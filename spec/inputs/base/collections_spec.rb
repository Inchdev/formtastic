require 'fast_spec_helper'
require 'inputs/base/collections'

class MyInput
  include Formtastic::Inputs::Base::Collections
end

RSpec.describe MyInput do
  let(:builder) { double }
  let(:template) { double }
  let(:model_class) { double }
  let(:model) { double(:class => model_class) }
  let(:model_name) { "post" }
  let(:method) { double }
  let(:options) { Hash.new }
  
  let(:instance) { MyInput.new(builder, template, model, model_name, method, options) }

  # class Whatever < ActiveRecord::Base
  #   enum :status => [:active, :archived]
  # end
  #
  # Whatever.statuses
  #
  # Whatever.new.status
  #
  # f.input :status
  describe "#collection_from_enum" do
    
    let(:method) { :status }

    context "when an enum is defined for the method" do
      before do
        statuses = ActiveSupport::HashWithIndifferentAccess.new("active"=>0, "inactive"=>1)
        allow(model_class).to receive(:statuses) { statuses }
        allow(model).to receive(:defined_enums) { {"status" => statuses } }
      end

      context 'no translations available' do
        it 'returns an Array of EnumOption objects based on the enum options hash' do
          expect(instance.collection_from_enum).to eq [["Active", "active"],["Inactive", "inactive"]]
        end
      end

      context 'with translations' do
        before do
          ::I18n.backend.store_translations :en, :activerecord => {
            :attributes => {
              :post => {
                :statuses => {
                  :active => "I am active",
                  :inactive => "I am inactive"
                }
              }
            }
          }
        end
        it 'returns an Array of EnumOption objects based on the enum options hash' do
          expect(instance.collection_from_enum).to eq [["I am active", "active"],["I am inactive", "inactive"]]
        end

        after do
          ::I18n.backend.store_translations :en, {}
        end
      end
    end

    context "when an enum is not defined" do
      it 'returns nil' do
        expect(instance.collection_from_enum).to eq nil
      end
    end
  end

  describe "#included" do
    module CustomBaseCollections
      def collection_from_association
        'foo'
      end
    end

    let(:instance) { AnotherInput.new(builder, template, model, model_name, method, options) }

    before(:context) do
      Formtastic::FormBuilder.base_input_collections_module_override = CustomBaseCollections
      class AnotherInput
        include Formtastic::Inputs::Base
        include Formtastic::Inputs::Base::Collections
      end
    end

    after(:context) do
      Formtastic::FormBuilder.base_input_collections_module_override = nil
    end

    it 'overrides the collection_from_association method' do
      expect(instance.collection_from_association).to eq('foo')
    end
  end

end

