require 'berkshelf/patch/berkshelf'

if ENV['LOG_LEVEL'].upcase.include?('DEBUG') and ENV['BERKSHELF_DEBUG'].nil?
  ENV['BERKSHELF_DEBUG'] = 'true'
end

if ARGV.include?('-bc')
  switch_index = ARGV.index('-bc')
  ARGV.delete_at(switch_index)
  ENV['BERKSHELF_ACTION'] = 'cache'
elsif ARGV.include?('-bu')
  switch_index = ARGV.index('-bu')
  ARGV.delete_at(switch_index)
  ENV['BERKSHELF_ACTION'] = 'update'
elsif ARGV.include?('-bi')
  switch_index = ARGV.index('-bi')
  ARGV.delete_at(switch_index)
  ENV['BERKSHELF_ACTION'] = 'install'
end

if ARGV.include?('-bio')
  switch_index = ARGV.index('-bio')
  ARGV.delete_at(switch_index)
  ENV['BERKSHELF_IGNORE_OVERRIDES'] = 'true'
  ENV['BERKSHELF_ACTION'] = 'update'
end
