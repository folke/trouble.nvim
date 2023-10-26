local Spec = require("trouble.spec")

describe("parses specs", function()
  it("parses a sort spec", function()
    local f1 = function() end
    ---@type ({input:trouble.Sort.spec, output:trouble.Sort})[]
    local tests = {
      {
        input = "foo",
        output = { { field = "foo" } },
      },
      {
        input = { "foo", "bar" },
        output = { { field = "foo" }, { field = "bar" } },
      },
      {
        input = { "foo", "-bar" },
        output = { { field = "foo" }, { field = "bar", desc = true } },
      },
      { input = f1, output = { { sorter = f1 } } },
      { input = { buf = 0 }, output = { { filter = { buf = 0 } } } },
      { input = { { buf = 0 } }, output = { { filter = { buf = 0 } } } },
      { input = { f1, "foo" }, output = { { sorter = f1 }, { field = "foo" } } },
    }

    for _, test in ipairs(tests) do
      assert.same(test.output, Spec.sort(test.input))
    end
  end)

  it("parses a group spec", function()
    ---@type ({input:trouble.Group.spec, output:trouble.Group})[]
    local tests = {
      {
        input = "foo",
        output = { fields = { "foo" }, format = "{foo}" },
      },
      {
        input = "foo",
        output = { fields = { "foo" }, format = "{foo}" },
      },
      {
        input = { "foo", "bar" },
        output = { fields = { "foo", "bar" }, format = "{foo} {bar}" },
      },
      {
        input = { "foo", "bar" },
        output = { fields = { "foo", "bar" }, format = "{foo} {bar}" },
      },
      {
        input = { "foo", "bar" },
        output = { fields = { "foo", "bar" }, format = "{foo} {bar}" },
      },
      {
        input = {
          "directory",
          format = "{kind_icon} {symbol.name} {text:Comment} {pos}",
        },
        output = {
          directory = true,
          format = "{kind_icon} {symbol.name} {text:Comment} {pos}",
        },
      },
    }

    for _, test in ipairs(tests) do
      assert.same(test.output, Spec.group(test.input))
    end
  end)

  it("parses a section spec", function()
    local tests = {
      {
        input = {
          -- error from all files
          source = "diagnostics",
          groups = { "filename" },
          filter = {
            severity = 1,
          },
          sort = { "filename", "-pos" },
        },
        output = {
          events = {},
          source = "diagnostics",
          groups = { { fields = { "filename" }, format = "{filename}" } },
          sort = { { field = "filename" }, { field = "pos", desc = true } },
          filter = { severity = 1 },
          format = "{filename} {pos}",
        },
      },
    }
    for _, test in ipairs(tests) do
      assert.same(test.output, Spec.section(test.input))
    end
  end)
end)
