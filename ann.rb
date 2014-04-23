require 'ruby-fann'

class Ann

  Max_Epochs = 10000
  Epochs_Between_Reports = 50
  Default_Hidden_Neurons = [400]

  # the path to the training data folder
  Training_Data_Folder = "training_data"
  # the path to the test data folder
  Test_Data_Folder = "test_data"
  # the path to the config file folder
  Config_Folder = "config"

  ANN_Class_Values = {"no_admit" => "1 0 0", "admit_no_matriculate" => "0 1 0", "admit_matriculate" => "0 0 1"}

  def initialize(params = {})
    if params[:training_file_name]
      @training_file = "#{Training_Data_Folder}/#{params[:training_file_name]}"
      header_tokens = File.open(@training_file, &:gets).split.map! {|token| token.to_i}
      @fann = RubyFann::Standard.new(num_inputs: header_tokens[1], hidden_neurons: (params[:hidden_neurons] || Default_Hidden_Neurons), num_outputs: header_tokens[2])
    elsif params[:config_file_name]
      @fann = RubyFann::Standard.new(filename: "#{Config_Folder}/#{params[:config_file_name]}")
    else
      puts "Unrecognized parameters"
    end
  end
  
  def train(desired_error)
    data = RubyFann::TrainData.new(filename: @training_file)
    @fann.train_on_data(data, Max_Epochs, Epochs_Between_Reports, desired_error)
  end
  
  def train_and_save(desired_error = 0.001, config_file = "ann_config.txt")
    train(desired_error)
    @fann.save("#{Config_Folder}/#{config_file}")
  end

  def rate_accuracy(test_file_name)
    test_data = []

    File.open("#{Test_Data_Folder}/#{test_file_name}") do |f|
      2.times {f.gets} # get rid of header

      f.each_line do |line|
        case line.chomp
        when "" #ignore blank lines
        when /^[01] [01] [01]$/
          class_value = line.chomp.split(' ').map! {|n| n.to_f}
          test_data << [@attributes, class_value]
        else
          @attributes = line.chomp.split(' ').map! {|n| n.to_f}
        end
      end
    end

    confusion_matrix = {:_TOTAL => test_data.size}
    test_data.each do |instance|
      class_representation = instance.delete_at(instance.size - 1).inject('') {|string,node| string << "#{node.to_i} "}.chomp(' ')
      actual_class_value = ANN_Class_Values.key(class_representation)
      predicted_class_value = ANN_Class_Values.key(assign_class_value(@fann.run(instance.first)))
puts "predicted_class_value: #{predicted_class_value}"
      confusion_matrix[actual_class_value] ||= {:_TOTAL => 0}
      confusion_matrix[actual_class_value][:_TOTAL] += 1 
      confusion_matrix[actual_class_value][predicted_class_value] ||= 0
      confusion_matrix[actual_class_value][predicted_class_value] += 1 
    end                                     
    confusion_matrix
  end

  def assign_class_value(output)
    class_value_string = "0 0 0"
    max = output.max
    class_value_string[2 * output.index(max)] = "1"
    class_value_string
  end
end

if __FILE__ == $0
  Ann.new(training_file_name: "ann_training_data.txt").train_and_save
  #Ann.new(config_file_name: "ann_config.txt").rate_accuracy("ann_test_data.txt")
end
