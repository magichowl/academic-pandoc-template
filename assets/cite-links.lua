function Cite(cite)
  local citationId = cite.citations[1].id
  if citationId then
    local refId = "ref-" .. citationId
    local link = pandoc.Link(cite.content, "#" .. refId)
    link.classes = {"citation"}
    return link
  end
  return cite
end

function Div(div)
  if div.classes:includes("CSL-bib-body") then
    local counter = 0
    return pandoc.walk_block(div, {
      Div = function(bibEntry)
        counter = counter + 1
        bibEntry.identifier = "ref-" .. (bibEntry.identifier:match("ref%-([^%-%s]+)") or counter)
        return bibEntry
      end
    })
  end
  return div
end
