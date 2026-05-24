﻿-- expand-macros.lua
-- 扩展 LaTeX 宏并为带 \label 的公式添加标记

local function has_label(elem)
    -- 检查公式中是否有 \label
    if elem.text then
        return elem.text:find('\\label')
    end
    if elem.c then
        for i = 1, #elem.c do
            if type(elem.c[i]) == 'string' and elem.c[i]:find('\\label') then
                return true
            end
        end
    end
    return false
end

function Math(elem)
    if has_label(elem) then
        -- 为带标签的公式添加标记
        return {
            elem,
            pandoc.RawInline('openxml', '<w:r><w:t>EQUATION_NUMBER</w:t></w:r>')
        }
    end
    return elem
end

function Para(elem)
    return elem
end