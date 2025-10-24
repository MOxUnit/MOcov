// C implementation of mocov_line_covered.m
//
// The C code below implements storing and retrieving file coverage state.
// It is intended for use with Octave. It runs considerably faster
// than the .m code. To use it, it needs compiling using 'mex' in Octave.
// (Matlab has its own mechanism to keep track of file coverage)
//
// The functions belowd keeps tracks of coverage of a set of files in a
// variable pointer `*state`. For each file, for every line the number of times
// it has been executed is stored. This is represented by a struct
// `covered_files` (for all covered files) which keeps an array of
// `covered_file` structs (one for each file). There are helper functions
// for allocating and freeing space for these structs when needed.
//
// To help with debugging, the code defines and uses `debug()` en
// `debug_print_state()` calls.

#include "mex.h"
#include <assert.h>
#include <math.h> // For isnan()
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// 0 -> no debugging messages; 1 -> print (lots of) debugging messages
#ifndef IS_DEBUG
#define IS_DEBUG 0
#endif

// Octave represents a string literal through a pointer. By caching the
// pointer, repeated string comparison calls can be avoided. This comes at the
// of roughly doubling memory requirements.
// Some basic benchmarking (Octave version 9.4.0, Mac silicon, 2025) suggests
// that no cache may be slightly faster.
// 0 -> no cache (more string comparisons), 1 -> cache (requires more memory)
#ifndef CACHE_FILENAME_POINTERS
#define CACHE_FILENAME_POINTERS 0
#endif

typedef int line_count_t;

// Define helper that computes the maximum of two values
int max(int a, int b) { return (a > b) ? a : b; }

typedef struct {
    line_count_t count;
#if CACHE_FILENAME_POINTERS
    const mxArray *filename_mx;
#endif
} covered_line;

// Structure to store covered lines for a single .m file
typedef struct {
    char *filename;      // Dynamically allocated string for the filename
    size_t capacity;     // Size of line_counts
    size_t n_lines;      // Largest line number encountered so far
    covered_line *lines; // For each line how often it was executed
} covered_file;

// Structure to store covered lines for a list of .m files
typedef struct {
    size_t n_files;      // Number of files
    size_t capacity;     // Size of files
    covered_file *files; // Array of covered_file structs (one for each file)
} covered_files;

// Declare constants
// (these should not be changed unless you really know what you are doing)
#define GENERAL_STRING_BUFFER_LENGTH 100
#define MAX_ERROR_ID_LENGTH 200
#define MAX_ERROR_MESSAGE_LENGTH GENERAL_STRING_BUFFER_LENGTH

const char *ERROR_ID_PREFIX = "mocov_line_covered:";
const char *MALLOC_ERROR_MESSAGE_PREFIX = "memory allocation failed: ";

#if IS_DEBUG
const int DEBUG_BUFFER_SIZE = GENERAL_STRING_BUFFER_LENGTH;
const char *DEBUG_PREFIX = "DEBUG: ";
#endif

// The persistent variable that will store the internal state.
static covered_files *state = NULL;

// Function defined below.
void raise_mex_error(const char *error_id_label, const char *error_message);

////////////
// Debugging helpers

// Wrapper around mexPrintf that only prints if IS_DEBUG is true
void debug(const char *fmt, ...) {
#if IS_DEBUG
    // Declare a buffer to hold the formatted message
    char buffer[DEBUG_BUFFER_SIZE];

    // Declare a va_list to handle the variable arguments
    va_list args;
    va_start(args, fmt);

    // Use snprintf to format the string into the buffer with the DEBUG_PREFIX
    int n = snprintf(buffer, DEBUG_BUFFER_SIZE, "%s",
                     DEBUG_PREFIX); // Add the DEBUG_PREFIX

    // Check if the buffer has enough space to add the DEBUG_PREFIX
    if (n >= DEBUG_BUFFER_SIZE) {
        // If the prefix itself doesn't fit, call raise_mex_error and exit early
        raise_mex_error("debug:prefix_too_long", "Prefix exceeds buffer size");
        return;
    }

    // Calculate the remaining space in the buffer
    size_t remaining_space = DEBUG_BUFFER_SIZE - n;

    // Try to format the rest of the message into the buffer
    int formatted_length = vsnprintf(buffer + n, remaining_space, fmt, args);

    // Check if vsnprintf truncates the message
    if (formatted_length >= remaining_space) {
        // If the message is truncated, call raise_mex_error and exit early
        raise_mex_error("debug:message_too_long",
                        "Formatted message exceeds buffer size");
        return;
    }

    // Print the formatted message using mexPrintf
    mexPrintf("%s\n", buffer);

    // Clean up the va_list
    va_end(args);
#endif
}

void debug_print_state() {
#if IS_DEBUG
    // Print the size of the covered_files structure
    covered_files *cfs = state;
    if (cfs == NULL) {
        mexPrintf("  state is NULL\n");
    } else {
        size_t n_files = cfs->n_files;
        mexPrintf("  state: .n_files=%zu, .capacity=%zu\n", n_files,
                  cfs->capacity);

        // Iterate through the list of files in the covered_files structure
        for (size_t i = 0; i < n_files; i++) {
            // Print key for each file
            covered_file *cf = &cfs->files[i];
            if (cf == NULL) {
                mexPrintf("    files[%zu] is NULL,", i);
            } else {
                char *filename = cf->filename;
                size_t n_lines =
                    cf->n_lines; // Number of elements in line_counts
                mexPrintf(
                    "    files[%zu].filename=%s, .n_lines=%zu, .capacity=%zu, ",
                    i, filename, n_lines, cf->capacity);

                // Print line counts for each file's covered_lines
                if (cf->lines == NULL) {
                    mexPrintf(".lines is NULL\n");
                } else {
                    mexPrintf(".lines=[ "); // Print size first
                    for (size_t j = 0; j < n_lines; j++) {
                        mexPrintf("%i ", cf->lines[j].count);
                    }
                    mexPrintf("]\n");
                }
            }
        }
    }
#endif
}

////////////
// Mex error helper functions
void raise_mex_error(const char *error_id_label, const char *error_message) {
    // Use fixed buffer for the full error_id with sufficient space
    char error_id[MAX_ERROR_ID_LENGTH];

    // Ensure that the total length does not exceed MAX_ERROR_ID_LENGTH
    if (strlen(ERROR_ID_PREFIX) + strlen(error_id_label) + 1 >=
        MAX_ERROR_ID_LENGTH) {
        mexErrMsgIdAndTxt("mocov_line_covered:string_too_long",
                          "Error ID exceeds allocated buffer size.");
        exit(1);
    }

    // Concatenate the prefix and the original error_id into new_errorid
    snprintf(error_id, MAX_ERROR_ID_LENGTH, "%s%s", ERROR_ID_PREFIX,
             error_id_label);

    // Call the original mexErrMsgIdAndTxt function with the new error_id
    mexErrMsgIdAndTxt(error_id, error_message);

    exit(
        1); // should never get here: mexErrMsgIdAndTxt should exit the function
}

// Utility function to check for NULL pointer after memory allocation
void raise_mex_error_if_null_pointer(void *ptr,
                                     const char *additional_message) {
    if (ptr != NULL) {
        return;
    }

    // Declare a buffer for the error message
    char error_message[MAX_ERROR_MESSAGE_LENGTH];

    // Calculate the total length required for the error message
    size_t n_prefix = strlen(MALLOC_ERROR_MESSAGE_PREFIX);
    size_t n_additional_message = strlen(additional_message);
    size_t n_total =
        n_prefix + n_additional_message + 1; // +1 for the null terminator

    // Check if the total length exceeds the buffer size
    if (n_total >= MAX_ERROR_MESSAGE_LENGTH) {
        raise_mex_error("memory_allocation_failed",
                        "error message buffer too small");
    }

    // Construct the full error message if it's within the buffer limit
    snprintf(error_message, MAX_ERROR_MESSAGE_LENGTH, "%s%s",
             MALLOC_ERROR_MESSAGE_PREFIX, additional_message);

    // Call raise_mex_error to handle the error
    raise_mex_error("memory_allocation_failed", error_message);
}

////////////
// Operations on data structures

// Function to initialize file_covered_lines with empty values
void init_covered_file(covered_file *file) {
    file->filename = NULL;
    file->n_lines = 0;
    file->capacity = 0;
    file->lines = NULL;
}

// Function to extend the file_covered_lines struct
void extend_covered_file(covered_file *file, size_t new_capacity) {
    if (new_capacity <= file->capacity) {
        return; // Exit early if the current capacity is sufficient
    }

    // Reallocate memory for the line_counts array
    covered_line *new_lines =
        realloc(file->lines, new_capacity * sizeof(covered_line));
    raise_mex_error_if_null_pointer(
        new_lines, "Failed to resize line_counts in covered_file");

    for (size_t i = file->capacity; i < new_capacity; i++) {
        new_lines[i].count = 0;
#if CACHE_FILENAME_POINTERS
        new_lines[i].filename_mx = NULL;
#endif
    }
    // TODO: can we use memset instead? This might assume that NULL==0...
    // memset(new_lines + file->capacity, 0,
    //       (new_capacity - file->capacity) * sizeof(covered_line));

    // Update the structure with the new size and line_counts
    file->lines = new_lines;
    file->capacity = new_capacity;
}

// Function to extend the file_covered_lines struct if index does not fit
void extend_to_fit_covered_file(covered_file *file, int index) {
    if (index >= file->capacity) {
        size_t new_capacity =
            (size_t)index * 2 +
            1; // Ensuring the new size is at least twice the index + 1
        extend_covered_file(file, new_capacity);
    }
    file->n_lines = max(file->n_lines, index + 1);
}

// Function to clean up memory used by file_covered_lines
void free_covered_file(covered_file *file) {
    free(file->filename);
    file->filename = NULL;

    free(file->lines);
    file->lines = NULL;

    file->n_lines = 0;
    file->capacity = 0;
}

// Function to extend the covered_files struct
void extend_covered_files(covered_files *cfs, size_t new_capacity) {
    if (new_capacity <= cfs->capacity) {
        return; // Exit early if the new size is less than or equal to the
                // current size
    }

    // Reallocate memory for the array of covered_file structs
    covered_file *new_files =
        realloc(cfs->files, new_capacity * sizeof(covered_file));
    raise_mex_error_if_null_pointer(
        new_files, "Failed to resize covered_file array in covered_files");

    // Initialize the newly added covered_file structs
    for (size_t i = cfs->capacity; i < new_capacity; i++) {
        init_covered_file(&new_files[i]);
    }

    // Update the structure with the new size and covered_file array
    cfs->files = new_files;
    cfs->capacity = new_capacity;
}

// Function to extend the covered_files struct if index does not fit
void extend_to_fit_covered_files(covered_files *cfs, int index) {
    if (index < cfs->capacity) {
        return;
    }
    size_t new_capacity =
        (size_t)index * 2 +
        1; // Ensuring the new capacity is at least twice the index + 1
    extend_covered_files(cfs, new_capacity);
    cfs->n_files = max(cfs->n_files, index + 1);
}

// Functions that operate on internal state
void free_state() {
    debug("free state");
    if (state == NULL) {
        return;
    }
    if (state->files != NULL) {
        for (int i = 0; i < state->n_files; i++) {
            free_covered_file(&state->files[i]);
        }
        free(state->files);
    }
    free(state);
}

void init_state() {
    debug("init state");

    free_state();

    state = malloc(sizeof(covered_files));
    if (state == NULL) {
        raise_mex_error_if_null_pointer(state, "init state");
    }

    state->n_files = 0;
    state->capacity = 0;
    state->files = NULL;
}

// Convert double to int, raise error if not possible
int double_to_int(double double_value) {
    // Check if the value is NaN
    if (isnan(double_value)) {
        raise_mex_error("InvalidInput", "value is NaN");
    }

    // Cast the double to an integer once
    int int_value = (int)double_value;

    // Check if the value is a non-integer double (i.e., fractional part exists)
    if (double_value != int_value) {
        raise_mex_error("InvalidInput", "value is non-integer double");
    }

    return int_value;
}

// Helper function to convert singular mx Double to integer
int get_scalar_int_from_mx_double(const mxArray *mx_arr,
                                  char *message_on_failure) {
    // Ensure input is a double scalar (1 element)
    if (!mxIsDouble(mx_arr) || mxGetNumberOfElements(mx_arr) != 1) {
        raise_mex_error("InvalidInput", message_on_failure);
    }
    double double_value = mxGetScalar(mx_arr);
    return double_to_int(double_value);
}

// Register the cleanup function to be called when Matlab / Octave exits
// or the MEX file is unloaded
void cleanup() { free_state(); }

// Register the cleanup function to run on mexAtExit
// (This is called just before a mex function is cleared, or Matlab / Octave
// are terminated).
void register_cleanup() { mexAtExit(cleanup); }

// Helper function to add a line state count
void add_line_covered(int idx, const mxArray *fn_mx, int line_number) {

    debug("add line covered idx=%i, line_number (base 0)=%i", idx, line_number);
    debug_print_state();

    extend_to_fit_covered_files(state, idx);
    covered_file *cf = &state->files[idx];
    extend_to_fit_covered_file(cf, line_number);
    cf->lines[line_number].count++;

    const bool needs_to_set_filename = cf->filename == NULL;

    // conditional block when using caching, unconditional otherwise
#if CACHE_FILENAME_POINTERS
    if (needs_to_set_filename || cf->lines[line_number].filename_mx != fn_mx)
#endif
    {
        char *fn = mxArrayToString(fn_mx);
        raise_mex_error_if_null_pointer(fn, "fn in update_state");

        if (needs_to_set_filename) {
            cf->filename = fn;
        } else {
            const bool is_filename_mismatch = strcmp(cf->filename, fn) != 0;
            // make sure memory is freed before raising exception
            free(fn);
            if (is_filename_mismatch) {
                raise_mex_error("FileNameMismatch",
                                "File name mismatch, this should not happen");
            }
        }
#if CACHE_FILENAME_POINTERS
        // update filename pointer
        cf->lines[line_number].filename_mx = fn_mx;
#endif
    }

    debug("done adding line covered");
    debug_print_state();
}

// Function to return the state
void return_state(const mxArray *prhs[], int nlhs, mxArray *plhs[]) {
    if (nlhs > 1) {
        raise_mex_error("TooManyOutputs",
                        "This function accepts at most one output.");

    } else if (nlhs == 0) {
        // No output, nothing to do, we can exit this function early.
        return;
    }

    debug("Return state, which is:");
    debug_print_state();

    // Cast size_t to mwSize for correct compatibility with mx functions
    int n_files = state->n_files;
    mwSize mw_n_files = (mwSize)n_files;

    mxArray *mx_keys_cell = mxCreateCellArray(1, &mw_n_files);
    raise_mex_error_if_null_pointer(mx_keys_cell, "mx_keys_cell");

    mxArray *mx_line_counts_cell = mxCreateCellArray(1, &mw_n_files);
    raise_mex_error_if_null_pointer(mx_line_counts_cell, "mx_line_counts_cell");

    for (size_t i = 0; i < n_files; i++) {
        covered_file *cf = &state->files[i];
        bool has_cf = cf != NULL;

        // cached filenames (keys)
        bool has_filename = has_cf && cf->filename != NULL;
        char *cached_key = has_filename ? cf->filename : "";
        mxArray *mx_cached_key = mxCreateString(cached_key);
        raise_mex_error_if_null_pointer(mx_cached_key, "mx_cached_key");
        mxSetCell(mx_keys_cell, i, mx_cached_key);
        debug("file %i: has_filename=%i, key=%s", i, has_filename, cached_key);

        // cached line counts
        bool has_line_count = has_cf && cf->lines != NULL;

        // Return a row vector for each file (when debugging it's more
        // readable).
        size_t n_rows = has_line_count ? cf->n_lines : 0;
        size_t n_columns = 1;
        size_t n_items = n_columns * n_rows;

        mxArray *mx_line_count =
            mxCreateNumericMatrix(n_rows, n_columns, mxDOUBLE_CLASS, mxREAL);
        raise_mex_error_if_null_pointer(mx_line_count, "mx_line_count");

        mxDouble *arr_line_count = calloc(n_items, sizeof(mxDouble));
        raise_mex_error_if_null_pointer(mx_line_count, "arr_line_count");

        for (size_t j = 0; j < n_items; j++) {
            // copy line counts one-by-one
            arr_line_count[j] = (mxDouble)cf->lines[j].count;
        }

        memcpy(mxGetData(mx_line_count), arr_line_count,
               n_items * sizeof(double));
        free(arr_line_count);
        mxSetCell(mx_line_counts_cell, i, mx_line_count);
    }

    plhs[0] =
        mxCreateStructMatrix(1, 1, 2, (const char *[]){"keys", "line_count"});
    mxSetField(plhs[0], 0, "keys", mx_keys_cell);
    mxSetField(plhs[0], 0, "line_count", mx_line_counts_cell);
}

// Function to handle nrhs == 1 case (setting the state)
void set_state(const mxArray *prhs[], int nlhs, mxArray *plhs[]) {
    if (nlhs > 1) {
        mexErrMsgIdAndTxt("mocov_line_covered:TooManyOutputs",
                          "This function accepts only one output.");
    }
    debug("Setting state, original value was:");
    debug_print_state();

    // always clear the cache and start from fresh
    init_state();

    debug("... state has been initialized.");

    // Set default values in case of empty input
    mwSize n_keys = 0;
    mwSize n_line_counts = 0;
    size_t n_files = 0;

    mxArray *keys_array = NULL;
    mxArray *line_count_array = NULL;

    // Special case: support empty input [] (the empty array)
    bool has_empty_input =
        (mxIsDouble(prhs[0]) && mxGetNumberOfElements(prhs[0]) == 0);

    if (!has_empty_input) {
        // The usual case: state is set using a struct with fields
        // .keys and .line_count. This means extra checks need to be done.
        if (!mxIsStruct(prhs[0])) {
            raise_mex_error("InvalidInput", "Input must be a struct.");
        }

        if (mxGetNumberOfElements(prhs[0]) != 1) {
            raise_mex_error("InvalidInput", "Input struct must have size 1x1");
        };

        keys_array = mxGetField(prhs[0], 0, "keys");
        line_count_array = mxGetField(prhs[0], 0, "line_count");

        if (keys_array == NULL || line_count_array == NULL) {
            mexErrMsgIdAndTxt(
                "mocov_line_covered:MissingFields",
                "Input struct must have 'keys' and 'line_count' fields.");
            return; // make static checker happy
        }

        // Set required space for state
        n_keys = mxGetNumberOfElements(keys_array);
        n_line_counts = mxGetNumberOfElements(line_count_array);

        debug("n_keys=%i, n_line_counts=%i", n_keys, n_line_counts);

        if (n_keys != n_line_counts) {
            mexErrMsgIdAndTxt("mocov_line_covered:InvalidInput",
                              "Input struct fields .keys and .line_count have "
                              "different number of elements");
            return; // make static checker happy
        }
        n_files = (size_t)n_keys;
        debug("cache size from input: %i", n_files);
    }

    if (n_files == 0) {
        return;
    }

    extend_covered_files(state, n_files);

    for (size_t i = 0; i < n_files; i++) {
        mxArray *mx_key = mxGetCell(keys_array, i);

        raise_mex_error_if_null_pointer(mx_key, "mx_key");

        if (!mxIsChar(mx_key)) {
            raise_mex_error("InvalidInput", "Input key element must be string");
        }

        // filename
        char *filename = mxArrayToString(mx_key);
        raise_mex_error_if_null_pointer(filename, "filename");

        // line counts
        mxArray *mx_line_count = mxGetCell(line_count_array, i);
        raise_mex_error_if_null_pointer(mx_line_count, "mx_line_count");

        if (!mxIsDouble(mx_line_count)) {
            raise_mex_error(
                "InvalidInput",
                "Input line count array must all be of double type");
        }

        mwSize n_elements = mxGetNumberOfElements(mx_line_count);

        size_t n_lines = (size_t)n_elements;
        debug("setting %i", i);

        double *line_count = mxGetData(mx_line_count);
        raise_mex_error_if_null_pointer(line_count, "line_count");
        debug("setting %i", i);

        covered_file *cf = &state->files[i];
        init_covered_file(cf);
        cf->filename = filename;
        cf->n_lines = n_lines;
        extend_covered_file(cf, n_lines);
        for (size_t j = 0; j < n_lines; j++) {
            cf->lines[j].count = (line_count_t)double_to_int(line_count[j]);
#if CACHE_FILENAME_POINTERS
            cf->lines[j].filename_mx = NULL;
#endif
        }
        state->n_files = (i + 1);
    }

    debug("Setting state, state is now:");
    debug_print_state();
}

// Helper function to handle nrhs == 3 case (update the state with a specific
// line state)
void update_state(const mxArray *prhs[], int nlhs, mxArray *plhs[]) {

    debug("updating state");
    int idx = get_scalar_int_from_mx_double(prhs[0], "arg 1 of 3") -
              1; // Convert to 0-base line number

    if (!mxIsChar(prhs[1])) {
        raise_mex_error("InvalidInput", "arg 2 of 3 must be a string");
    }

    int line_number = get_scalar_int_from_mx_double(prhs[2], "arg 3 of 3") -
                      1; // Convert to 0-base line number

    // call helper function
    debug("call 3 args");
    add_line_covered(idx, prhs[1], line_number);

    debug("updating state: done, state is now");
    debug_print_state();
}

// The main mexFunction that calls set_state or update_state based on nrhs
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Register the cleanup function to be called on exit
    register_cleanup();

    // - first invocation:  make sure state is initialized
    // - later invocations: keep (persistent) state
    if (state == NULL) {
        init_state();
    }

    if (nrhs == 3) {
        // Most common case: update the state for a specific line in a file.
        update_state(prhs, nlhs, plhs);
    } else if (nrhs == 1) {
        // Set the state from a struct s with s.keys and s.line_count
        set_state(prhs, nlhs, plhs);
    } else if (nrhs != 0) {
        mexErrMsgIdAndTxt("mocov_line_covered:TooManyInputs",
                          "This function accepts zero, one, or three inputs.");
        return; // make static checker happy
    }

    // always return the internal state. If nrhs==0, this does nothing.
    return_state(prhs, nlhs, plhs);
}
