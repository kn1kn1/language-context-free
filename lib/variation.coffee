utils = null

# Variation code model.
#
#  Variation code is a string which consists of 1 to 6 upper case alphabet.
#  ('A' ~ 'ZZZZZZ')
module.exports =
class Variation
  constructor: (str) ->
    @value = str.toUpperCase()

  # Check if specified str is alphabetic.
  #
  # str: The {String} to be checked.
  #
  # Returns true if specified str is alphabetic.
  @isAlphabetic: (str) ->
    return /^[a-zA-Z]+$/.test(str)

  # Check if specified str is a valid variation code.
  #
  # str: The {String} to be checked.
  #
  # Returns true if specified str is valid.
  @isValid: (str) ->
    return false if !str
    return false unless @isAlphabetic(str)
    str.length <= 6

  # Add the variation by one.
  #
  # If added result is overflow, the result will be rotated to 'A'.
  #
  # Returns The {String} new(added) variation code.
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
    utils = require "./utils"
    utils.dumpObj codes
    for code in codes
      newValue = newValue + String.fromCharCode(code)
    @value = newValue
