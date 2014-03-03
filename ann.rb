require 'ruby-fann'

class Ann

  Max_Epochs = 10000
  Epochs_Between_Reports = 50
  Default_Hidden_Neurons = [50,100,100,50]

  def initialize(params = {})
    if params[:training_file_name]
      header_tokens = File.open(file_name, &:gets).split
      @fann = RubyFann::Standard.new(num_inputs: header_tokens[1], hidden_neurons: (params[:hidden_neurons] || Default_Hidden_Neurons), num_outputs: header_tokens[2])
      @training_file = training_file_name
    elsif params[:config_file_name]
      @fann = RubyFann::Standard.new(filename: file_name)
    else
      puts "Unrecognized parameters"
    end
  end
  
  def train(desired_error)
    data = RubyFann::TrainData.new(file_name: @training_file)
    @fann.train_on_data(data, Max_Epochs, Epochs_Between_Reports, desired_error)
  end
  
  def train_and_save(desired_error, config_file)
    train_on_data(desired_error)
    @fann.save(config_file)
  end
end
