
class MarkovChain
  
  # 
  # +data+ is #data() of the other MarkovChain. It becomes owned by the
  # returned MarkovChain.
  # 
  def self.from(data)
    new(data)
  end
  
  # 
  # creates an empty MarkovChain.
  # 
  # +data+ is a map which becomes owned by this MarkovChain.
  # 
  def initialize(data = {})
    @data = data
    @last_state = nil
  end
  
  # 
  # appends +states+ to the end of this MarkovChain.
  # 
  # +states+ is an Array of arbitrary objects.
  # 
  # It returns this (modified) MarkovChain.
  # 
  def append!(states)
    for next_state in states
      state_occurences_map = (@data[@last_state] or Hash.new)
      state_occurences_map[next_state] ||= 0
      state_occurences_map[next_state] += 1
      @data[@last_state] = state_occurences_map
      @last_state = next_state
    end
    return self
  end
  
  #
  # returns Enumerable of predicted states. The states are predicted by
  # states passed to #append!().
  # 
  # The result may contain nils. Each nil means that MarkovChain could not
  # predict a state after the one before nil. Example:
  # 
  #   markov_chain.predict().take(4)  #=>  ["a", "c", "b", nil]
  #   
  # That means +markov_chain+ could not predict a state after "b".
  # 
  def predict()
    self.extend(Prediction)
  end
  
  # 
  # +data+ passed to MarkovChain.new() or MarkovChain.from().
  # 
  def data
    @data
  end
  
  private
  
  # :enddoc:
  
  # 
  # This module is only intended for inclusion into MarkovChain.
  # 
  module Prediction
    
    include Enumerable
    
    def each
      #
      last_state = @last_state
      loop do
        #
        next_state = begin
          state_occurences_map = (@data[last_state] or Hash.new)
          occurences_sum = state_occurences_map.reduce(0) do |sum, entry|
            sum + entry[1]
          end
          choice = rand(occurences_sum + 1)
          chosen_state_and_occurences = state_occurences_map.find do |state, occurences|
            choice -= occurences
            choice <= 0 
          end
          chosen_state_and_occurences ||= [nil, nil]
          chosen_state_and_occurences[0]
        end
        #
        yield next_state
        #
        last_state = next_state
      end
    end
    
  end
  
end
