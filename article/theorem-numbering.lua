-- theorem-numbering.lua
-- Auto-numbering and cross-referencing for theorem-like environments.
-- Place AFTER pandoc-crossref, BEFORE citeproc/multiple-bibliographies.

local THEOREM_TYPES = {
  definition  = {prefix = "def", title = "Definition"},
  theorem     = {prefix = "thm", title = "Theorem"},
  lemma       = {prefix = "lem", title = "Lemma"},
  corollary   = {prefix = "cor", title = "Corollary"},
  proposition = {prefix = "prp", title = "Proposition"},
  proof       = {prefix = "prf", title = "Proof"},
  example     = {prefix = "ex",  title = "Example"},
  exercise    = {prefix = "exr", title = "Exercise"},
}

function Pandoc(doc)
  local registry = {}
  local counters = {}

  -- -------------------------------------------------------------------------
  -- Pass 1: scan all blocks, collect theorem IDs and assign numbers.
  -- -------------------------------------------------------------------------
  local function scan(blocks)
    for _, blk in ipairs(blocks) do
      if blk.t == "Div" then
        for _, cls in ipairs(blk.classes) do
          local tdef = THEOREM_TYPES[cls]
          if tdef and blk.identifier
             and blk.identifier:match("^" .. tdef.prefix .. ":") then
            counters[cls] = (counters[cls] or 0) + 1
            registry[blk.identifier] = {
              type  = cls,
              num   = counters[cls],
              title = tdef.title
            }
          end
        end
        scan(blk.content)
      end
    end
  end
  scan(doc.blocks)

  -- -------------------------------------------------------------------------
  -- Pass 2: modify all divs (add numbering) and cites (resolve references).
  -- -------------------------------------------------------------------------
  local function block_mod(blk)
    -- Handle theorem divs
    if blk.t == "Div" then
      local info = registry[blk.identifier]
      if info then
        local prefix = info.title .. " " .. info.num
        if #blk.content > 0 and blk.content[1].t == "Header" then
          blk.content[1].content = {pandoc.Str(prefix)}
        elseif #blk.content > 0 and blk.content[1].t == "Para" then
          table.insert(blk.content[1].content, 1, pandoc.Space())
          table.insert(blk.content[1].content, 1, pandoc.Strong{pandoc.Str(prefix)})
        else
          table.insert(blk.content, 1, pandoc.Para{
            pandoc.Strong{pandoc.Str(prefix)}
          })
        end
      end
    end
    -- Walk inline content for theorem cite resolution
    return pandoc.walk_block(blk, { Cite = resolve_cite })
  end

  function resolve_cite(el)
    if #el.citations == 1 then
      local info = registry[el.citations[1].id]
      if info then
        return pandoc.Link(
          pandoc.Str(info.title .. " " .. info.num),
          "#" .. el.citations[1].id
        )
      end
    end
  end

  -- Walk document blocks
  local blocks = {}
  for _, blk in ipairs(doc.blocks) do
    blocks[#blocks + 1] = block_mod(blk)
  end
  doc.blocks = blocks
  return doc
end

return { Pandoc = Pandoc }