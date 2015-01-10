Variation = require '../lib/variation'

describe "Variation", ->

  describe "when the isAlphabetic is called", ->
    it "returns true if the arg is alphabetic", ->
      expect(Variation.isAlphabetic('A')).toBe(true)

  describe "when the isValid is called", ->
    it "returns true if the arg is alphabetic", ->
      expect(Variation.isValid('A')).toBe(true)

    it "returns true if the arg is a number", ->
      expect(Variation.isValid('1')).toBe(false)

    it "returns true if the arg is null", ->
      expect(Variation.isValid(null)).toBe(false)

    it "returns true if the arg is undefined", ->
      expect(Variation.isValid(undefined)).toBe(false)

    it "returns true if the arg is blank", ->
      expect(Variation.isValid('')).toBe(false)

  describe "when the @add1 is called", ->
    it "increase its alphabetic value by one", ->
      variation = new Variation 'A'
      added = variation.add1()
      expect(added).toBe('B')
      expect(variation.value).toBe('B')

    it "increase its alphabetic value by one", ->
      variation = new Variation 'AA'
      added = variation.add1()
      expect(added).toBe('AB')
      expect(variation.value).toBe('AB')

    it "increase the length if the former value is 'Z'", ->
      variation = new Variation 'Z'
      added = variation.add1()
      expect(added).toBe('AA')
      expect(variation.value).toBe('AA')

    it "reset its value to 'A' when the result overflow", ->
      variation = new Variation 'ZZZZZZ'
      added = variation.add1()
      expect(added).toBe('A')
      expect(variation.value).toBe('A')
