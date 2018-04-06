module SpecHelper
  module UnitHelpers
    def expect_xml_eql?(xml1, xml2)
      expect(xml1.lines.map(&:strip).join.strip).to eq(xml2.lines.map(&:strip).join.strip)
    end
  end
end
