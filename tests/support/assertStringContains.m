function assertStringContains(text, subtext)
  assert(~isempty(strfind(text, subtext)), ...
    'String ''%s'' should contain ''%s'', but it doesn''t.', text, subtext);
end
