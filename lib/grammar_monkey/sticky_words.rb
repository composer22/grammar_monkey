require 'csv'

module GrammarMonkey
  module StickyWords

    # Load table word + usage (first char is primary)
    # mask:
    # D = article
    # v = adverb
    # C = conjuntion
    # P = preposition
    #
    DATA_FILEPATH = File.dirname(__FILE__) + '/data/'
    DICTIONARY    = 'sticky_words.csv'

    def self.extended(base)
      sticky_words = {}
      CSV.foreach(DATA_FILEPATH + DICTIONARY, headers: true) do |row|
        sticky_words[row[0].downcase] = row[1]
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