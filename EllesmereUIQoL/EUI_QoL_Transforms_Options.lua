-------------------------------------------------------------------------------
--  EUI_QoL_Transforms_Options.lua
--  Builds the "Transforms" page inside the Quality of Life module: the granular
--  per-item picker for the Remove Transforms feature. Categories act as quick
--  "select all" switches; each individual transform can also be toggled on its
--  own. The item definitions come from EllesmereUI.RemoveTransformsData, which
--  is owned by the runtime (EllesmereUIQoL.lua).
-------------------------------------------------------------------------------

_G._EUI_BuildTransformsPage = function(pageName, parent, yOffset)
    local W = EllesmereUI.Widgets
    local y = yOffset
    local _, h
    local data = EllesmereUI.RemoveTransformsData

    parent._showRowDivider = true

    -- Intro text (matches the Shifter/Bags page style)
    do
        local fontPath = (EllesmereUI.GetFontPath and EllesmereUI.GetFontPath())
            or "Fonts\\FRIZQT__.TTF"
        local infoFrame = CreateFrame("Frame", nil, parent)
        infoFrame:SetSize(parent:GetWidth(), 34)
        infoFrame:SetPoint("TOP", parent, "TOP", 0, y - 10)
        infoFrame._isSpacer = true
        local line1 = infoFrame:CreateFontString(nil, "OVERLAY")
        line1:SetFont(fontPath, 15, "")
        line1:SetTextColor(1, 1, 1, 0.75)
        line1:SetPoint("TOP", infoFrame, "TOP", 0, 0)
        line1:SetJustifyH("CENTER")
        line1:SetText(EllesmereUI.L("Choose which transforms are removed automatically when applied to you."))
        local line2 = infoFrame:CreateFontString(nil, "OVERLAY")
        line2:SetFont(fontPath, 15, "")
        line2:SetTextColor(1, 1, 1, 0.75)
        line2:SetPoint("TOP", line1, "BOTTOM", 0, -2)
        line2:SetJustifyH("CENTER")
        line2:SetText(EllesmereUI.L("Transforms applied during combat are removed as soon as combat ends."))
        y = y - 50
    end

    -- Master switch (mirrors the toggle on the Quality of Life tab; both write
    -- EllesmereUIDB.removeTransforms and stay in sync via RefreshPage).
    _, h = W:SectionHeader(parent, "REMOVE TRANSFORMS", y);  y = y - h
    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Enable Remove Transforms",
          tooltip = "Master switch for the feature. The transforms selected below are only removed while this is enabled.",
          getValue = function()
              return EllesmereUIDB and EllesmereUIDB.removeTransforms or false
          end,
          setValue = function(v)
              if not EllesmereUIDB then EllesmereUIDB = {} end
              EllesmereUIDB.removeTransforms = v
              if EllesmereUI._applyRemoveTransforms then
                  EllesmereUI._applyRemoveTransforms()
              end
              EllesmereUI:RefreshPage()
          end },
        { type = "label", text = "" }
    );  y = y - h

    if not data then
        return math.abs(y)
    end

    -- Group items by category, preserving definition order.
    local catItems = {}
    for _, item in ipairs(data.items) do
        catItems[item.cat] = catItems[item.cat] or {}
        table.insert(catItems[item.cat], item)
    end

    local function ItemCfg(item)
        return {
            type = "toggle",
            text = item.label,
            getValue = function()
                return EllesmereUI.GetTransformItemEnabled(item.key)
            end,
            setValue = function(v)
                EllesmereUI.SetTransformItemEnabled(item.key, v)
                EllesmereUI:RefreshPage()
            end,
        }
    end

    for _, cat in ipairs(data.order) do
        local items = catItems[cat]
        if items and #items > 0 then
            local catLabel = data.labels[cat] or cat
            _, h = W:SectionHeader(parent, string.upper(catLabel), y);  y = y - h

            -- Category "select all / none" convenience toggle.
            _, h = W:DualRow(parent, y,
                { type = "toggle", text = "All " .. catLabel,
                  tooltip = "Enable or disable every transform in this category at once.",
                  getValue = function()
                      for _, it in ipairs(items) do
                          if not EllesmereUI.GetTransformItemEnabled(it.key) then
                              return false
                          end
                      end
                      return true
                  end,
                  setValue = function(v)
                      for _, it in ipairs(items) do
                          EllesmereUI.SetTransformItemEnabled(it.key, v)
                      end
                      EllesmereUI:RefreshPage()
                  end },
                { type = "label", text = "" }
            );  y = y - h

            -- Individual transforms, two per row.
            local i = 1
            while i <= #items do
                local leftCfg  = ItemCfg(items[i])
                local rightCfg = items[i + 1] and ItemCfg(items[i + 1]) or { type = "label", text = "" }
                _, h = W:DualRow(parent, y, leftCfg, rightCfg);  y = y - h
                i = i + 2
            end
        end
    end

    return math.abs(y)
end
