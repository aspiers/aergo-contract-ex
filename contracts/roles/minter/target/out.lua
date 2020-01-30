-- from http://lua-users.org/wiki/LuaTypeChecking
--
-- Type check function that decorates functions.
-- supported type: string, number, function, boolean, nil, userdata, address, bignum
-- Example:
--   sum = typecheck('number', 'number', '->', 'number')(
--     function(x, y) return x + y end
--   )

function typecheck(...)
  local types = {...}

  local function check(got, expected)
    if (got and expected == 'address') then
      assert(type(got) == 'string', "address must be string type")
      -- check address length
      assert(52 == #got, string.format("invalid address length: %s (%s)", got, #got))
      -- check character
      local invalidChar = string.match(got, '[^123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]')
      assert(nil == invalidChar,
        string.format("invalid address format: %s contains invalid char %s", got, invalidChar or 'nil'))
    elseif (got and expected == 'bignum') then
      -- check bignum
      assert(bignum.isbignum(got), string.format("expected %s but got %s", expected, type(got)))
    else
      -- check default lua types
      assert(type(got) == expected, string.format("expected %s but got %s", expected or 'nil', type(got)))
    end
  end

  return function(f)
    local function returncheck(i, ...)
      -- Check types of return values.
      if types[i] == "->" then i = i + 1 end
      local j = i
      while types[i] ~= nil do
        check(select(i - j + 1, ...), types[i])
        i = i + 1
      end
      return ...
    end
    return function(...)
      -- Check types of input parameters.
      local i = 1
      while types[i] ~= nil and types[i] ~= "->" do
        check(select(i, ...), types[i])
        i = i + 1
      end
      return returncheck(i, f(...))  -- call function
    end
  end
end

state.var{
    _minter = state.map(), -- string -> boolean
}

minterInit = function ()
	_minter[system.getCreator()] = true
end

isMinter = typecheck('address', '->', 'boolean')(function (account)
	return _minter[account] or false
end)

onlyMinter = function() 
	assert(isMinter(system.getSender()), 'minter only')
end

addMinter =  typecheck('address', '->')(function (account) onlyMinter()
	_minter[account] = true
end)

renounceMinter = function() 
	_minter[system.getSender()] = false
end