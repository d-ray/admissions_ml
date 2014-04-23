require 'decisiontree'

class Tree

  # the path to the training data folder
  Training_Data_Folder = "training_data"
  # the path to the test data folder
  Test_Data_Folder = "test_data"
  # the path to the config file folder
  Config_Folder = "config"

  # initialized with either a file of training data or a config file if training has already taken place
  def initialize(params = {})
    if params[:training_file_name]
      @attributes = []
      @attribute_types = {}
      default_value = ""
      training_data = [] # each data instance represented by an array with attribute values and class value last
  
      File.open("#{Training_Data_Folder}/#{params[:training_file_name]}") do |f|
        header_array = f.gets.chomp.split(',')
        header_array.each do |attribute_with_type|
          attribute_type_pair = attribute_with_type.split(':')
          @attributes << attribute_type_pair.first
          @attribute_types[attribute_type_pair.first.to_sym] = attribute_type_pair.last.to_sym
        end
  
        default_value = f.gets.chomp
  
        f.each_line do |line|
          training_data << extract_data_instance(line)
        end
      end
  
      @tree = DecisionTree::ID3Tree.new(@attributes, training_data, default_value, @attribute_types)
    elsif params[:config_file_name]
      @tree = DecisionTree::ID3Tree.load_from_file("#{Config_Folder}/#{params[:config_file_name]}")
    else
      puts "Unrecognized parameters"
    end
  end

  def self.from_file(config_file_name)
    @tree = DecisionTree::ID3Tree.load_from_file(config_file_name)
  end

  def train
    @tree.train
  end

  def train_and_save(config_file = "id3_config.txt")
    @tree.train
    @tree.graph("decision_tree_graph")
    @tree.ruleset
    @tree.save_to_file("#{Config_Folder}/#{config_file}")
  end

  def graph
    @tree.graph("decision_tree_graph")
  end

  def ruleset
    @tree.ruleset
  end

  def rate_accuracy(test_file_name)
    test_data = []
    @attributes = []
    @attribute_types = {}
    File.open("#{Test_Data_Folder}/#{test_file_name}") do |f|
      header_array = f.gets.chomp.split(',')
      header_array.each do |attribute_with_type|
        attribute_type_pair = attribute_with_type.split(':')
        @attributes << attribute_type_pair.first
        @attribute_types[attribute_type_pair.first.to_sym] = attribute_type_pair.last.to_sym
      end

      f.gets # ignore default value
      f.each_line do |line|
        test_data << extract_data_instance(line)
      end
    end

    confusion_matrix = {:_TOTAL => test_data.size}
    test_data.each do |instance|
      actual_class_value = instance.delete_at(instance.size - 1)
      predicted_class_value = @tree.predict(instance)
      confusion_matrix[actual_class_value] ||= {:_TOTAL => 0}
      confusion_matrix[actual_class_value][:_TOTAL] += 1
      confusion_matrix[actual_class_value][predicted_class_value] ||= 0
      confusion_matrix[actual_class_value][predicted_class_value] += 1
    end
    confusion_matrix
  end

  def predict(instance)
    puts "The decision tree predicts that instance #{instance.inspect} will have class value #{@tree.predict(instance)}."
  end

  private

  def extract_data_instance(line)
    data_instance = line.chomp.split(/[,:]/)
    @attributes.each_with_index do |attribute, index|
      # change continuous attributes to floats rather than strings
      if @attribute_types[attribute.to_sym] == :continuous
        data_instance[index] = data_instance[index].to_f
      end
    end
    data_instance
  end
end

if __FILE__ == $0
  #Tree.new(:training_file_name => "id3_train_binary_decision.txt") .train_and_save("id3_binary_config.txt")
  tree = Tree.new(:config_file_name => "id3_config.txt") .rate_accuracy("id3_test_data.txt")
end
