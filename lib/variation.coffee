utils = require "./utils"

module.exports =
class Variation
  map = {}

  @setVariation: (filePath, variation) ->
    map[filePath] = variation

  @getVariation: (filePath) ->
    map[filePath]

  constructor: (str) ->
    @value = str.toUpperCase()

  @isAlphabetic: (str) ->
    return /^[a-zA-Z]+$/.test(str)

  @isValid: (str) ->
    return false if !str
    return false unless @isAlphabetic(str)
    str.length <= 6

  add1: ->
    codes = []
    for v, i in @value
      codes[i] = @value.charCodeAt(i)

    carry = 1
    valueLen = @value.length
    for i in [valueLen - 1..0]
      charCode = codes[i]
      charCode = charCode + carry
      if charCode > 90  # > 'Z'
        codes[i] = 65 # set 'A'
        carry = 1
      else
        codes[i] = charCode
        carry = 0

    # overflow
    return @value = 'A' if (carry is 1) and (valueLen is 6)

    newValue = if carry is 1 then 'A' else ''
    utils.dumpObj codes
    for code in codes
      newValue = newValue + String.fromCharCode(code)
    @value = newValue
