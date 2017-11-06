require 'json'
require 'cfndsl'

module CfnDsl::Functions

  def add_stack_id_tag
    Property(
      'Tags',
      [{
        'Key'   => 'StackId',
        'Value' => Ref('AWS::StackId')
      }]
    )
  end

end
