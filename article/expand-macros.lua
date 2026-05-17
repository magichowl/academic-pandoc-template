-- 宏展开过滤器
-- 支持从外部文件读取宏定义，同时保留内置宏作为后备

-- 内置宏定义（作为后备）
local builtin_macros = {
  ["\\x"] = "\\mathbf{x}",
  ["\\X"] = "\\mathbf{X}",
  ["\\loss"] = "\\mathcal{L}",
  ["\\func"] = {"f(%1,%2,%3)", 3},
  ["\\add"] = {"%1 + %2", 2},
  ["\\mult"] = {"%1 \\times %2", 2},
  ["\\vec"] = {"\\mathbf{%1}", 1},
  ["\\mat"] = {"\\mathbf{%1}", 1},
}

local macros = {}
local macros_loaded = false

function find_matching_brace_full(str, start_pos)
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

function parse_newcommand(line)
  local name_start = line:find("\\newcommand%s*{%s*\\")
  if not name_start then return nil end
  
  local name_start = name_start + #("\\newcommand{")
  local name_end = line:find("}", name_start)
  if not name_end then return nil end
  
  local name = "\\" .. line:sub(name_start, name_end - 1):gsub("%s+", "")
  
  local num_params = 0
  local pos = name_end + 1
  
  while pos <= #line and line:sub(pos, pos):match("%s") do
    pos = pos + 1
  end
  
  if line:sub(pos, pos) == "[" then
    local num_end = line:find("]", pos)
    if num_end then
      num_params = tonumber(line:sub(pos + 1, num_end - 1)) or 0
      pos = num_end + 1
    end
  end
  
  while pos <= #line and line:sub(pos, pos):match("%s") do
    pos = pos + 1
  end
  
  if line:sub(pos, pos) ~= '{' then return nil end
  
  local body_end = find_matching_brace_full(line, pos)
  if not body_end then return nil end
  
  local body = line:sub(pos + 1, body_end - 1)
  local expanded_body = body:gsub("#(%d)", "%%%1")
  
  return name, num_params, expanded_body
end

function load_macros_from_file(filepath)
  local file = io.open(filepath, "r")
  if not file then return false end
  
  local content = file:read("*all")
  file:close()
  
  for line in content:gmatch("[^\r\n]+") do
    line = line:gsub("%%.*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    
    if line:match("^\\newcommand") then
      local name, num_params, body = parse_newcommand(line)
      
      if name then
        if num_params == 0 then
          macros[name] = body
        else
          macros[name] = {body, num_params}
        end
      end
    end
  end
  
  return true
end

function ensure_macros_loaded()
  if macros_loaded then return end
  
  -- 首先复制内置宏
  for k, v in pairs(builtin_macros) do
    macros[k] = v
  end
  
  -- 尝试加载外部宏定义文件（会覆盖内置宏）
  local paths = {
    "macros.tex",
    "./macros.tex",
    "../article/macros.tex",
    "f:/academic-pandoc-template/article/macros.tex"
  }
  
  for _, path in ipairs(paths) do
    if load_macros_from_file(path) then
      break
    end
  end
  
  macros_loaded = true
end

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
  ensure_macros_loaded()
  
  if elem.text then
    elem.text = expand_macros(elem.text)
  end
  return elem
end