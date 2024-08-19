function retval = is_octave
    retval = (exist ('OCTAVE_VERSION', 'builtin') > 0);
end
