VariationHolder = require '../lib/variation-holder'

describe "VariationHolder", ->

  describe "when the VariationHolder.map is refered", ->
    it "is undefined", ->
      expect(VariationHolder.map).not.toBeDefined()
