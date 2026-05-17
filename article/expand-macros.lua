-- Macro expansion filter
-- Uses built-in macro definitions, does not load external files

local macros = {
  ["\\add"] = {"%1 + %2", 2},
  ["\\func"] = {"f(%1,%2,%3)", 3},
  ["\\loss"] = "\\mathcal{L}",
  ["\\mat"] = {"\\mathbf{%1}", 1},
  ["\\mult"] = {"%1 \\times %2", 2},
  ["\\X"] = "\\mathbf{X}",
  ["\\x"] = "\\mathbf{x}",
}

function find_matching_brace(str, start_pos)
  local depth = 1
  local pos = start_pos + 1
  while pos <= #str and depth > 0 do
    local char = str:sub(pos, pos)
    if char == '{' then depth = depth + 1
    elseif char == '}' then depth = depth - 1 end
    pos = pos + 1
  end
  return pos - 1
end

function parse_macro_args(text, pos, num_params)
  local params = {}
  local current_pos = pos
  
  while true do
    while current_pos <= #text and text:sub(current_pos, current_pos) ~= '{' do
      current_pos = current_pos + 1
    end
    
    if current_pos > #text then break end
    
    local end_pos = find_matching_brace(text, current_pos)
    if end_pos then
      table.insert(params, text:sub(current_pos + 1, end_pos - 1))
      current_pos = end_pos + 1
      
      if num_params > 0 and #params >= num_params then break end
    else
      break
    end
  end
  
  return params, current_pos
end

function expand_macros_once(text)
  local result = ""
  local pos = 1
  
  while pos <= #text do
    local matched = false
    
    for macro_name, macro_def in pairs(macros) do
      local macro_len = #macro_name
      local macro_start = text:find(macro_name, pos, true)
      
      if macro_start and macro_start == pos then
        matched = true
        
        if macro_start > pos then
          result = result .. text:sub(pos, macro_start - 1)
        end
        
        if type(macro_def) == "string" then
          result = result .. macro_def
          pos = macro_start + macro_len
          
        else
          local pattern = macro_def[1]
          local num_params = macro_def[2]
          
          local params, next_pos = parse_macro_args(text, macro_start + macro_len, num_params)
          
          local valid = true
          if num_params > 0 and #params ~= num_params then
            valid = false
          elseif num_params == -1 and #params == 0 then
            valid = false
          end
          
          if valid then
            for i, param in ipairs(params) do
              params[i] = expand_macros(param)
            end
            
            local expanded = pattern
            
            if num_params == -1 then
              local args_str = table.concat(params, ",")
              expanded = expanded:gsub("%%args%%", args_str)
            else
              for i, param in ipairs(params) do
                expanded = expanded:gsub("%%" .. i, param)
              end
            end
            
            result = result .. expanded
            pos = next_pos
          else
            result = result .. text:sub(macro_start, next_pos - 1)
            pos = next_pos
          end
        end
        
        break
      end
    end
    
    if not matched then
      result = result .. text:sub(pos, pos)
      pos = pos + 1
    end
  end
  
  return result
end

function expand_macros(text)
  local result = text
  local prev_result = ""
  local iterations = 0
  local max_iterations = 10
  
  while result ~= prev_result and iterations < max_iterations do
    prev_result = result
    result = expand_macros_once(result)
    iterations = iterations + 1
  end
  
  return result
end

function Math(elem)
  if elem.text then
    elem.text = expand_macros(elem.text)
  end
  return elem
end
