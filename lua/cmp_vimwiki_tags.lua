local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })

  self.cache = {}
  self.rg_job = nil
  self.running_job_id = 0
  self.timer = vim.loop.new_timer()

  return self
end

function source.is_available()
  return vim.bo.filetype == "vimwiki"
end

function source.get_debug_name()
  return "vimwiki-tags"
end

function source.get_trigger_characters()
  return { "@" }
end

function source.get_keyword_pattern()
  return [[@\(\a\|\d\)*]]
end

function source.complete(self, params, callback)
  local function on_event(_, data, event)
    if event == "stdout" then
      local items = {}
      local dups = {}
      -- Remove duplicates
      for _, v in pairs(data) do
        -- Remove illegal characters
        local label = v:gsub(",", "")
        label = label:gsub("`", "")

        if dups[label] == nil then
          dups[label] = true
          table.insert(items, { label = label })
        end
      end

      callback({ items = items, isIncomplete = false })
    end
  end

  self.timer:stop()
  self.timer:start(
    -- TODO: Make debounce parameter
    100,
    0,
    vim.schedule_wrap(function()
      vim.fn.jobstop(self.running_job_id)
      local rg_options = {
        "--no-heading",
        "--no-filename",
        "--no-line-number",
        "--only-matching",
      }

      local cmd = string.format(
        "rg %s %s %s",
        table.concat(rg_options, " "),
        "'@(\\w|\\d)+'",
        "~/Seafile/default/Documents/vim-pad"
      )
      self.running_job_id = vim.fn.jobstart(
        cmd,
        {
          on_stderr = on_event,
          on_stdout = on_event,
          on_exit = on_event,
          -- TODO: Make CWD parameter
          cwd = vim.fn.getcwd(),
        }
      )
    end)
  )
end

return source
