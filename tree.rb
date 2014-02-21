require 'decisiontree'

class Tree

  def initialize(training_file_name)
    attributes = []
    attribute_types = {}
    default_value = ""
    training_data = [] # each data instance represented by an array with attribute values and class value last

    File.open(training_file_name) do |f|
      header_array = f.gets.chomp.split(',')
      header_array.each do |attribute_with_type|
        attribute_type_pair = attribute_with_type.split(':')
        attributes << attribute_type_pair.first
        attribute_types[attribute_type_pair.first.to_sym] = attribute_type_pair.last.to_sym
      end

      default_value = f.gets.chomp

      f.each_line do |line|
        attributes_class_pair = line.chomp.split(':')
        data_instance = (attributes_class_pair.first.split(',') << attributes_class_pair.last)
        attributes.each_with_index do |attribute, index|
          # change continuous attributes to floats rather than strings
          if attribute_types[attribute.to_sym] == :continuous
            data_instance[index] = data_instance[index].to_f
          end
        end
        training_data << data_instance
      end
    end

    @tree = DecisionTree::ID3Tree.new(attributes, training_data, default_value, attribute_types)
  end

  def train
    @tree.train
  end

  def train_and_save

  end

  def predict(instance)
    puts "The decision tree predicts that instance #{instance.inspect} will have class value #{@tree.predict(instance)}."
  end
end

tree = Tree.new("id3_training_data.txt")
tree.train
