local Parser = require("trouble.config.parser")
describe("Input is parsed correctly", function()
  local tests = {
    {
      input = [[a = "b" foo = true bar=1 c = "g"]],
      expected = { opts = { a = "b", foo = true, bar = 1, c = "g" }, errors = {}, args = {} },
    },
    {
      input = [[key="value with spaces"]],
      expected = { opts = { key = "value with spaces" }, errors = {}, args = {} },
    },
    {
      input = [[arr={one, two}]],
      expected = { opts = { arr = { "one", "two" } }, errors = {}, args = {} },
    },
    {
      input = [[a.b = "c"]],
      expected = { opts = { a = { b = "c" } }, errors = {}, args = {} },
    },
    {
      input = [[vim=vim.diagnostic.severity.ERROR]],
      expected = { opts = { vim = vim.diagnostic.severity.ERROR }, errors = {}, args = {} },
    },
    {
      input = [[x.y.z = "value" a.b = 2]],
      expected = { opts = { x = { y = { z = "value" } }, a = { b = 2 } }, errors = {}, args = {} },
    },
    {
      input = [[test="hello world"]],
      expected = { opts = { test = "hello world" }, errors = {}, args = {} },
    },
    {
      input = [[one.two.three.four = 4]],
      expected = { opts = { one = { two = { three = { four = 4 } } } }, errors = {}, args = {} },
    },
    {
      input = [[a="b" c="d" e.f="g" h.i.j="k"]],
      expected = { opts = { a = "b", c = "d", e = { f = "g" }, h = { i = { j = "k" } } }, errors = {}, args = {} },
    },
    {
      input = [[empty = "" nonempty="not empty"]],
      expected = { opts = { empty = "", nonempty = "not empty" }, errors = {}, args = {} },
    },
    {
      input = [[win.position="right" win.relative="win"]],
      expected = { opts = { win = { position = "right", relative = "win" } }, errors = {}, args = {} },
    },
    {
      input = [[a.b="c" a = "b"]],
      expected = { opts = { a = "b" }, errors = {}, args = {} }, -- This test is tricky as it will overwrite the first value of 'a'
    },
    {
      input = [[a="b" a.b="c"]],
      expected = { opts = { a = { b = "c" } }, errors = {}, args = {} }, -- This test is tricky as it will overwrite the first value of 'a'
    },
    {
      input = [[a_b = 1]],
      expected = { opts = { a_b = 1 }, errors = {}, args = {} },
    },
    {
      input = "foo=bar bar=baz",
      expected = { opts = { foo = "bar", bar = "baz" }, errors = {}, args = {} },
    },
    {
      input = "foo=bar bar={ one, two, three} ",
      expected = { opts = { foo = "bar", bar = { "one", "two", "three" } }, errors = {}, args = {} },
    },
    {
      input = [[a.x = 1 a.y = 2 a = {z  =3}]],
      expected = { opts = { a = { z = 3 } }, errors = {}, args = {} },
    },
    {
      input = [[ a = {z  =3} a.x = 1 a.y = 2]],
      expected = { opts = { a = { x = 1, y = 2, z = 3 } }, errors = {}, args = {} },
    },
    {
      input = "foo",
      expected = { opts = {}, errors = {}, args = { "foo" } },
    },
    { input = "foo bar", expected = { opts = {}, errors = {}, args = { "foo", "bar" } } },
    {
      input = "foo bar baz",
      expected = { opts = {}, errors = {}, args = { "foo", "bar", "baz" } },
    },
  }

  for _, test in ipairs(tests) do
    it("parses " .. test.input, function()
      local actual = Parser.parse(test.input)
      assert.same(test.expected, actual)
    end)
  end

  return tests
end)
