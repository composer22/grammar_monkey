require 'csv'

module GrammarMonkey
  module StickyWords

    # Load table word + usage (first char is primary; second secondary)
    #
    # mask ONLY first and secondary usages:
    #
    # D = article
    # v = adverb
    # C = conjunction
    # P = preposition
    #
    DATA_FILEPATH = File.dirname(__FILE__) + '/data/'
    DICTIONARY    = 'sticky_words.csv'

    def self.extended(base)
      sticky_words = {}
      CSV.foreach(DATA_FILEPATH + DICTIONARY, headers: true) do |row|
        size = row[1].size > 1  ? row[1].scan(/^[v|C|B|P][v|C|B|P]/).size : row[1].scan(/^[v|C|B|P]/).size
        sticky_words[row[0].downcase] = row[1] if size > 0
      end

      base.class_eval do
        @sticky_words = sticky_words

        protected

        def self.sticky_words
          @sticky_words
        end
      end
    end

  end
end