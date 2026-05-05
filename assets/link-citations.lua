-- Lua filter to add links to citations
local citation_counter = 0
local citations = {}

function Para(elem)
  -- Process citations in paragraphs
  return pandoc.walk_block(elem, {
    Cite = function(cite)
      -- Collect citations and link them
      local num_str = cite.citations[1] and (citation_counter + 1) or ""
      if cite.citations[1] then
        citation_counter = citation_counter + 1
        -- Create a link that points to the reference section
        local link = pandoc.Link(
          cite.content,
          "#ref-" .. citation_counter
        )
        link.classes = {"citation"}
        return link
      end
      return cite
    end
  })
end

function Div(elem)
  -- Process references section
  if elem.classes:includes("references") then
    local ref_counter = 0
    return pandoc.walk_block(elem, {
      Div = function(div)
        if div.identifier then
          -- Add anchor to reference
          ref_counter = ref_counter + 1
          div.identifier = "ref-" .. ref_counter
          return div
        end
      end
    })
  end
end
