require 'ruby-fann'

class Ann

  Max_Epochs = 10000
  Epochs_Between_Reports = 50
  Default_Hidden_Neurons = [100,200,300,200,100]

  # the path to the training data folder
  Training_Data_Folder = "training_data"
  # the path to the test data folder
  Test_Data_Folder = "test_data"
  # the path to the config file folder
  Config_Folder = "config"

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
  
  def train_and_save(desired_error = 0.01, config_file = "ann_config.txt")
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
    
    classification_counts = {}
    test_data.each do |instance|
      class_value = instance.delete_at(instance.size - 1)
      classification_counts[class_value] ||= {correct: 0, total: 0}
      classification_counts[class_value][:total] += 1
puts "@fann.run(instance.first): #{@fann.run(instance.first)}"
      classification_counts[class_value][:correct] += 1 if (assign_class_value(@fann.run(instance.first)) == assign_class_value(instance.last)) #TODO: this is probably wrong
    end
    
    total_correct = 0
    classification_counts.values.each {|h| total_correct += h[:correct]}    
    puts "Total: #{total_correct} out of #{test_data.size} (#{(total_correct.to_f / test_data.size)}%) correctly classified"
    puts "By class value:"    
    classification_counts.each {|kv_pair| puts "Value #{kv_pair.first}: #{kv_pair.last[:correct]} out of #{kv_pair.last[:total]} (#{kv_pair.last[:correct].to_f / kv_pair.last[:total]}%) correctly classified"}
  end

  def assign_class_value(output)
    max = output.max
    output.index(max)
  end
end
 #Ann.new(training_file_name: "ann_training_data.txt").train_and_save
 Ann.new(config_file_name: "ann_config.txt").rate_accuracy("ann_test_data.txt")
