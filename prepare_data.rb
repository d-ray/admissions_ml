class PrepareData

  # the types of classifiers to prepare data for
  Classifiers = [:tree, :ann]
  # the path to the training data folder
  Training_Data_Folder = "training_data"
  # the path to the test data folder
  Test_Data_Folder = "test_data"

  # indices of attributes from the starting data file that should not appear in the prepared data
  Reject_Indices = [0,19,20,21,33]
  Admit_Date_Index = 19
  Enrollment_Date_Index = 20

  # ID3 specific values
  Attributes = [:gender, :ethnicity, :state, :postal_code, :country, :major1, :major2, :major3, :hs_CEEB_code, :hSGPA, :grad_year, :ACT_score, :SAT_score, :application_date, :initial_visit_code, :initial_visit_date, :initial_inquiry_code, :initial_inquiry_date, :first_source_app, :entry_term, :opportunity_type, :application_status, :scholarships, :scholarship_bumped, :academic_index, :academic_year, :total_family_income, :expected_family_contribution, :total_gift_aid]
  Attribute_Types = ["discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "continuous", "discrete", "continuous", "continuous", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "discrete", "continuous", "discrete", "continuous", "continuous", "continuous"]
  Default_Value = "no_admit"

  # ANN specific values
  # unknown discrete options: High School CEEB Code, Grad Year, Application date,Initial Visit Date,Date of First Inquiry,Entry Term,Acad Year
  Discrete_Options = [2,10,60,1,196,113,113,113,0,1,0,1,1,0,6,0,131,0,2,0,4,37,9,4,1,0,1,1,1] # the number of nodes to use in representing each discrete attribute (1 => continuous attribute)
  Continuous_Denominators = [0,0,0,100000,0,0,0,0,0,5,0,36,1600,0,0,0,0,0,0,0,0,0,0,0,10000,0,100000000,100000000,100000] # the number to divide each continuous attribute by to produce values <= 1 (0 => discrete attribute)
  ANN_Class_Values = {"no_admit" => "1 0 0", "admit_no_matriculate" => "0 1 0", "admit_matriculate" => "0 0 1"}

  # initialized with a csv file containing data instances for training/testing
  def initialize(training_data = {}, test_data = {}, data_file = "admissions_data.csv")
    Classifiers.each do |classifier|
      training_files[classifier] ||= "#{Training_Data_Folder}/#{classifier.to_s}_training_data.txt"
      test_files[classifier] ||= "#{Test_Data_Folder}/#{classifier.to_s}_test_data.txt"
    end

    @training_data = []
    @test_data = []
    File.open(data_file) do |f|
      f.gets # ignore header
      f.each_line do |line|
        line.gsub!(/".*,.*"/) {|attribute| "\\#{attribute.gsub(',','')}"} #remove commas contained in matched quotes
        instance_array = line.chomp.split(',')
        class_value = determine_class_value(instance_array)
        (Attributes.size + Reject_Indices.size - instance_array.size).times {instance_array << ""} #ensure the appropriate number of attributes in case trailing empty strings are dropped
        Reject_Indices.sort! {|m,n| n <=> m} # sort indices in descending order
        Reject_Indices.each {|n| instance_array.delete_at(n)}
        if rand(3) == 0
          @test_data << [instance_array, class_value]
        else
          @training_data << [instance_array, class_value]
        end
      end
    end
    @discrete_options_to_numbers = []
    @training_data.first.first.size.times {@discrete_options_to_numbers << {}} # contains one hash per attribute
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
      header << "#{attribute.to_s}:#{Attribute_Types[index]},"
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

  def determine_class_value(attributes)
    if attributes[Admit_Date_Index].empty?
      "no_admit"
    elsif attributes[Enrollment_Date_Index].empty?
      "admit_no_matriculate"
    else
      "admit_matriculate"
    end
  end

  def convert_discrete_attribute_to_numbers(attribute, index)
return "" if Discrete_Options[index] == 0
    attribute_option_hash = @discrete_options_to_numbers[index]
    attribute_option_hash[attribute] = attribute_option_hash.size if attribute_option_hash[attribute].nil?

    attribute_array = Array.new(Discrete_Options[index], 0)
    attribute_array[attribute_option_hash[attribute]] = 1
    attribute_array.to_s.gsub(/[\[\],]/, '')
  end
end

PrepareData.new("admissions_data.csv").prepare_data(:id3)
