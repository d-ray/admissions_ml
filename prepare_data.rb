class PrepareData

  # the types of classifiers to prepare data for
  Classifiers = [:tree, :ann]
  # the path to the training data folder
  Training_Data_Folder = "training_data"
  # the path to the test data folder
  Test_Data_Folder = "test_data"

  # indices of attributes from the starting data file that should not appear in the prepared data
  Reject_Indices = [18,19,20,21]

  # ID3 specific values
  Attributes = [:gender, :ethnicity, :state, :postal_code, :country, :entry_term, :enter_level, :application_status, :major1, :major2, :major3, :hs_CEEB_code, :hSGPA, :coll_cum_GPA, :grad_year, :ACT_score, :SAT_score, :application_date, :appl_rating, :appl_calc_rating, :app_misc2, :initial_visit_code, :initial_visit_date, :complete_app]
  Attribute_Types = [:discrete, :discrete, :discrete, :discrete, :discrete, :discrete, :discrete, :discrete, :discrete, :discrete, :discrete, :discrete, :continuous, :continuous, :continuous, :continuous, :continuous, :continuous, :continuous, :continuous, :discrete, :discrete, :continuous, :discrete]
  Default_Value = "no_admit"

  # ANN specific values
  Discrete_Options = [2,5,50,1,0,2,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,2] # the number of nodes to use in representing each discrete attribute (1 => continuous attribute)
  Continuous_Denominators = [0,0,0,100000,0,0,0,0,0,0,0,0,5,4,2100,36,1600,-1,100,100,0,0,-1,0] # the number to divide each continuous attribute by to produce values <= 1 (0 => discrete attribute)
  ANN_Class_Values = {"no_admit" => "1 0 0", "admit_no_matriculate" => "0 1 0", "admit_matriculate" => "0 0 1"}

  # initialized with a csv file containing data instances for training/testing
  def initialize(data_file)
    @training_data = []
    @test_data = []
    File.open(data_file) do |f|
      f.gets # ignore header
      f.each_line do |line|
        line.gsub!(/".*,.*"/) {|attribute| "\\#{attribute.gsub(',','')}"} #remove commas contained in matched quotes
        instance_array = line.chomp.split(',')
        (Attributes.size + Reject_Indices.size - instance_array.size).times {instance_array << ""} #ensure the appropriate number of attributes in case trailing empty strings are dropped
        class_info = []
        Reject_Indices.each {|n| class_info << instance_array.delete_at(n)}
        if rand(3) == 0
          @test_data << [instance_array, determine_class_value(class_info)]
        else
          @training_data << [instance_array, determine_class_value(class_info)]
        end
      end
    end
    @discrete_options_to_numbers = []
    @training_data.first.first.size.times {@discrete_options_to_numbers << {}}
  end

  # create data files specific to one of the classifiers for both training and testing
  def prepare_data(algorithm)
    case algorithm
    when :id3
      prepare_id3_data 
    when :ann
      prepare_ann_data
    when :all
      prepare_all_data
    end
  end

  private

  def prepare_all_data
    prepare_id3_data
    prepare_ann_data
  end

  def prepare_id3_data
    write_id3_file("#{Training_Data_Folder}/id3_training_data.txt", @training_data)
    write_id3_file("#{Test_Data_Folder}/id3_test_data.txt", @test_data)
  end

  def write_id3_file(file, data)
    header = ""
    Attributes.each_with_index do |attribute, index|
      header << "#{attribute.to_s}:#{Attribute_Types[index].to_s},"
    end
    File.open(file, "w") do |f|
      f.puts("#{header.chomp(',')}")
      f.puts(Default_Value)
      data.each do |instance|
        attributes = ""
        instance.first.each {|attribute| attributes << "#{attribute},"}
        f.puts("#{attributes.chomp(',')}:#{instance.last}") #attribute values : class value
      end
    end
  end

  def prepare_ann_data
    write_ann_file("#{Training_Data_Folder}/ann_training_data.txt", @training_data)
    write_ann_file("#{Test_Data_Folder}/ann_test_data.txt", @test_data)
  end

  def write_ann_file(file, data)
    num_inputs = 0
    Discrete_Options.each {|n| num_inputs += n}
    # header consists of number of inputs, number of data instances, and number of outputs
    header = "#{num_inputs} #{data.size} #{ANN_Class_Values.size}"

    File.open(file, "w") do |f|
      f.puts("#{header}\n\n")
      data.each do |instance|
        instance_data = ""
        instance.first.each_with_index do |attribute, index|
          if Discrete_Options[index] == 1
            # continuous attribute
            instance_data << "#{attribute.to_f / Continuous_Denominators[index]} "
          else
            # discrete attribute
            instance_data << "#{convert_discrete_attribute_to_numbers(attribute, index)} "
          end
        end
        f.puts("#{instance_data.chomp(' ')}\n\n")
        f.puts("#{ANN_Class_Values[instance.last]}\n\n")
      end
    end
  end

  def determine_class_value(class_info)
    if class_info[0].empty?
      "no_admit"
    elsif class_info[1].empty?
      "admit_no_matriculate"
    else
      "admit_matriculate"
    end
  end

  def convert_discrete_attribute_to_numbers(attribute, index)
    attribute_option_hash = @discrete_options_to_numbers[index]
    attribute_option_hash[attribute] = attribute_option_hash.size if attribute_option_hash[attribute].nil?

    attribute_array = Array.new(Discrete_Options[index], 0)
    attribute_array[attribute_option_hash[attribute]] = 1
    attribute_array.to_s.gsub(/[\[\],]/, '')
  end
end
