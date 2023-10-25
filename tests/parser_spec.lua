local Parser = require("trouble.config.parser")
describe("Input is parsed correctly", function()
  local tests = {
    {
      input = [[a = "b" foo = true bar=1 c = "g"]],
      expected = { a = "b", foo = true, bar = 1, c = "g" },
    },
    {
      input = [[a.b = "c"]],
      expected = { a = { b = "c" } },
    },
    {
      input = [[x.y.z = "value" a.b = 2]],
      expected = { x = { y = { z = "value" } }, a = { b = 2 } },
    },
    {
      input = [[test="hello world"]],
      expected = { test = "hello world" },
    },
    {
      input = [[one.two.three.four = 4]],
      expected = { one = { two = { three = { four = 4 } } } },
    },
    {
      input = [[a="b" c="d" e.f="g" h.i.j="k"]],
      expected = { a = "b", c = "d", e = { f = "g" }, h = { i = { j = "k" } } },
    },
    {
      input = [[empty = "" nonempty="not empty"]],
      expected = { empty = "", nonempty = "not empty" },
    },
    {
      input = [[win.position="right" win.relative="win"]],
      expected = { win = { position = "right", relative = "win" } },
    },
    {
      input = [[a.b="c" a = "b"]],
      expected = { a = "b" }, -- This test is tricky as it will overwrite the first value of 'a'
    },
    {
      input = [[a="b" a.b="c"]],
      expected = { a = { b = "c" } }, -- This test is tricky as it will overwrite the first value of 'a'
    },
    { input = [[a_b = 1]], expected = { a_b = 1 } },
  }

  for _, test in ipairs(tests) do
    it("parses " .. test.input, function()
      local actual = Parser.parse(test.input)
      assert.same(test.expected, actual)
    end)
  end

  return tests
end)
