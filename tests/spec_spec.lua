local Spec = require("trouble.spec")

describe("parses specs", function()
  it("parses a sort spec", function()
    local f1 = function() end
    ---@type ({input:trouble.spec.sort, output:trouble.Sort})[]
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
      { input = f1, output = { f1 } },
      { input = { f1, "foo" }, output = { f1, { field = "foo" } } },
    }

    for _, test in ipairs(tests) do
      assert.same(test.output, Spec.sort(test.input))
    end
  end)

  it("parses a group spec", function()
    ---@type ({input:trouble.spec.group, output:trouble.Group})[]
    local tests = {
      {
        input = "foo",
        output = { fields = { "foo" }, sort = { { field = "foo" } } },
      },
      {
        input = "-foo",
        output = { fields = { "foo" }, sort = { { field = "foo", desc = true } } },
      },
      {
        input = { "foo", "-bar" },
        output = { fields = { "foo", "bar" }, sort = { { field = "foo" }, { field = "bar", desc = true } } },
      },
      {
        input = { "foo", "-bar", sort = "baz" },
        output = { fields = { "foo", "bar" }, sort = { { field = "baz" } } },
      },
      {
        input = { "foo", "-bar", sort = "-baz" },
        output = { fields = { "foo", "bar" }, sort = { { field = "baz", desc = true } } },
      },
    }

    for _, test in ipairs(tests) do
      assert.same(test.output, Spec.group(test.input))
    end
  end)

  it("parses a section spec", function()
    local input = {
      -- error from all files
      source = "diagnostics",
      groups = { "filename" },
      filter = {
        severity = 1,
      },
      sort = { "filename", "pos" },
    }
    local output = {
      source = "diagnostics",
      groups = { { fields = { "filename" }, sort = { { field = "filename" } } } },
      sort = { { field = "filename" }, { field = "pos" } },
      filter = { severity = 1 },
    }
    assert.same(output, Spec.section(input))
  end)
end)
