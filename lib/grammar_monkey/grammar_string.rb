require 'csv'
require 'grammar_monkey/sticky_words'

module GrammarMonkey
  class GrammarString < String

    extend GrammarMonkey::StickyWords

    DEFAULT_MAX_RUNON_WORDS = 50

    IRREGULAR_VERBS = %w(arisen babysat beaten become bent begun bet bound bitten bled blown broken bred
                        brought broadcast built bought caught chosen come cost cut dealt dug done drawn
                        drunk driven eaten fallen fed felt fought found flown forbidden forgotten forgiven
                        frozen gotten given gone grown hung had heard hidden hit held hurt kept known lain
                        led left lent let lain lit lost made meant met paid put quit read ridden rung
                        risen run said seen sold sent set shaken shone shot shown shut sung sunk sat slept
                        slid spoken spent spun spread stood stolen stuck stung struck sworn swept swum swung
                        taken taught torn told thought thrown understood woken worn won withdrawn written
                        burned burnt dreamed dreamt learned smelled bet broadcast cut hit hurt let put quit
                        read set shut spread awoken)

    VERBS                    = %w(is are was were be being been)
    COORDINATED_CONJUNCTIONS = %w(for and not but or yet so)

    DATA_FILEPATH          = File.dirname(__FILE__) + '/data/'
    DICTIONARIES           = {
        misspellings:  'misspellings.csv',
        transitions:   'transitions.csv',
        wordiness:     'wordiness.csv',
        grammar_traps: 'miscellaneous.csv',
        sticky_words:  'sticky_words.csv'
    }

    # Work structure for analysis
    attr_accessor :sentences

    # Max number of words that make a runon sentence
    attr_accessor :max_runon_count

    # Standard deviation between short and long sentences in the text.  Useful for determining variety.
    attr_accessor :standard_deviation

    # @param [String] text the string to encode
    # @param [Integer] max_runon_count max number of words that make a runon sentence
    def initialize(text, max_runon_count = nil)
      super text
      get_sentences
      @max_ronon_count    = max_runon_count ? max_runon_count : DEFAULT_MAX_RUNON_WORDS
      @standard_deviation = 0.to_f
    end

    # This does it all
    #
    def analyze
      get_sentences
      scan_word_count
      scan_spelling
      scan_runons
      scan_coord_conjunct
      scan_transitions
      scan_wordiness
      scan_grammar_traps
      scan_passive_voice
      scan_sticky_words
      standard_deviation
      true
    end

    def get_sentences
      @sentences = []
      gsub(/[\.!?;]/, '.').split('.').map(&:strip).each { |s| @sentences << { text: s, analysis: {} } }
      true
    end

    def scan_word_count
      @sentences.each { |s| s[:analysis][:word_count] = s[:text].gsub(/[^-a-zA-Z\']/, ' ').split.size }
      true
    end

    def scan_spelling
      CSV.foreach(DATA_FILEPATH + DICTIONARIES[:misspellings], headers: true) do |row|
        @sentences.each do |s|
          if (count = s[:text].downcase.scan(/#{ '\b' + row[1] + '\b' }/).size) > 0
            s[:analysis][:misspellings] ||= []
            s[:analysis][:misspellings] << { error: row[1], correction: row[2], total: count }
          end
        end
      end
      true
    end

    def scan_runons
      @sentences.each { |s| s[:analysis][:runon] = true if s[:text].gsub(/[^-a-zA-Z\']/, ' ').split.size >= @max_ronon_count }
      true
    end

    def scan_coord_conjunct
      @sentences.each do |s|
        COORDINATED_CONJUNCTIONS.each do |cc|
          if (count = s[:text].downcase.scan(/#{ '\b' + cc + '\b' }/).size) > 0
            s[:analysis][:coord_conjunct] ||= 0
            s[:analysis][:coord_conjunct] += count
          end
        end
      end
      true
    end

    def scan_transitions
      file_scan(:transitions)
    end

    def scan_wordiness
      file_scan(:wordiness)
    end

    def scan_grammar_traps
      file_scan(:grammar_traps)
    end

    def scan_passive_voice
      @sentences.each do |s|
        last_verb = nil
        s[:text].gsub(/[^-a-zA-Z\']/, ' ').downcase.split.each do |w|
          if last_verb && (w[-1, 2] == 'ed' || IRREGULAR_VERBS.include?(w))
            key                          = (last_verb + ' ' + w).to_sym
            s[:analysis][:passives]      ||= {}
            s[:analysis][:passives][key] ||= 0
            s[:analysis][:passives][key] +=1
          end
          last_verb = VERBS.include?(w) ? w : nil
        end
      end
      true
    end

    def scan_sticky_words
      sticky_words = self.class.sticky_words
      @sentences.each do |s|
        s[:text].gsub(/[^-a-zA-Z\']/, ' ').split.each do |w|
          if sticky_words[w.downcase]
            s[:analysis][:sticky_words]         ||= { total: 0, adverbs: 0 }
            s[:analysis][:sticky_words][:total] += 1
            s[:analysis][:sticky_words][:adverbs] += 1  if sticky_words[w.downcase][0..0] == 'v'
          end
        end
      end
      true
    end

    def standard_deviation
      word_counts         = @sentences.map { |s| s[:text].gsub(/[^-a-zA-Z\']/, ' ').split.size }
      means               = (word_counts.inject(:+).to_f / @sentences.size)
      sum                 = word_counts.inject(0) { |sum, i| sum + (i - means) ** 2 }
      variance            = 1 / @sentences.size.to_f * sum
      @standard_deviation = Math.sqrt(variance)
      true
    end

    protected

    def file_scan(key)
      CSV.foreach(DATA_FILEPATH + DICTIONARIES[key], headers: true) do |row|
        search = row[1].downcase
        @sentences.each do |s|
          count = s[:text].downcase.scan(/#{ search }/).size
          if count > 0
            result = { total: count }
            result.merge!(correction: row[2]) if row[2]
            s[:analysis][key]                ||= {}
            s[:analysis][key][search.to_sym] = result
          end
        end
      end
      true
    end
  end
end
#
#text   = "It is funny how America complains so much about the safety of the community or the safety of the country. Yet they walk around provoking people of doing wrong. For instance sex offenders. Why is it that women get raped a lot on the streets? Or why do children get molested by a family member? Is there any defense that America can come up with that will make the world a better and safer place? Why not vote for Proposition 83. Prop 83 will protect our children by keeping child molesters in prison longer; keeping them away from schools and parks; and monitoring their movement after they are released. America is the country of freedom and rights. Sometimes people abuse that freedom a little too much. For instance women walking around with their little short skirts. Why do they dress like that? They also walk around showing their stomach and exposing their breast for the entire world to see. The only thing that they are doing is making their lives more dangerous. Yet, when they are raped they complain. Well they asked for it. I understand that this proposition will help the law by capturing the sex offenders, but how does a monitor stop the offender from doing the crime? Also it is funny how the law throws people in jail for exposing them self out in the public vomiting, while being drunk. Yet they do not throw whores in jail for exposing their butts while walking down the streets with their short mini skirts. This law passed on will not change the state. Other states in this country have tried this law and it was a failure. For example this law was passed on in the state of Iowa and they said that this proposition turned out to be a failure. The idea of the safety for the residency did not help to stop the sex offenses against children. It also did not improve children’s safety. There was a chart of 80% to 90% of sex crimes committed even though the sex offenders had the monitor on. These criminals did not go on to unknown residencies, but to their own or acquaintances. Residence restriction in this proposal goes against the purpose of the safety because the offenders will go on to harming the public. It might not be a big offense that the offenders do but they might for instance grab a persons butt. Also sociological way proves that a person likes to do the opposite and see how far they can push the law for instance. They are psycho people out in the world who don’t have the capability of thinking from right and wrong. They just go for what pleases them. Monitors will not stop a person with a mind like that. There was a page “Jessica’s law.” In this report it showed how every police, sheriff, district attorney, and other major laws were all for this proposition. If we made a survey to see what country has come to be the most lazy country that they invent every possible technology system that will decrease there work. It will be America. Since when was it a monitors job to track down a criminal? These officers and other major laws are only trying to have the “Jessica law” put through, so they do not have to put so much time in to just one offense crime. No matter what comes up in this world it will never make any sense. America, the “New World,” in the 1700’s was fighting for their freedom of tax. The Stamp Act was being but on by the governor and the Sons of Liberty was not buying this Act. They also fought the British because they were taxing the Americans for British goods. Now it is 2007 and the governor is taxing higher and higher. So contradicting, and yet we have the freedom? Well this law if having “every” sex offender but in jail them being punish with this monitor for life. That means even though it was a minor offense. Why not just kill the person? They really have no rights after having this monitor placed on them. Yet, it is funny how the officer tells the person being arrest the Miranda Law. “You have the right to…” What right? They do not give the offender any rights by having this new technology being place on them. This proposition assures all the people that these sex offenders will be stopped. Every two minutes a rape or sexual assault occurs and every 35 seconds a child is abused or neglected. How can this proposition be assured? Nobody can assure anything. Everyone has there own mind and life. Offenders will not stop doing anything by just having a monitor place on them. If the first war in America did not stop other wars from accruing then how can we stop the sex offenders? The only way is by doing what we have always done, build more prisons."
#
#require 'pp'
#text          = 'All in all, it was a dark and stormy abberant night, and I knew it was a acronym to the city; I kept walkin a lesser degree of distance. The world was fallen.'
#tester = GrammarMonkey::GrammarString.new(text)
#tester.analyze
#pp tester.sentences
