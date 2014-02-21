require 'ruby-fann'

class Ann
  def initialize(training_file_name, hidden_neurons)
    header_tokens = File.open(file_name, &:gets).split
    @fann = RubyFann::Standard.new(num_inputs: header_tokens[1], hidden_neurons: hidden_neurons, num_outputs: header_tokens[2])
    @training_file = training_file_name
  end
  
  def initialize_from_file(file_name)
    @fann = RubyFann::Standard.new(filename: file_name)
  end
  
  def train(desired_error)
    data = RubyFann::TrainData.new(file_name: @training_file)
    @fann.train_on_data(data, 10000, 50, desired_error)
  end
  
  def train_and_save(desired_error, config_file)
    train_on_data(desired_error)
    @fann.save(config_file)
  end
end
