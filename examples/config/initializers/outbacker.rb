
#
# Specify where the Outbacker module cannot be included.
# If you try to include Outbacker within subclasses of
# ActiveRecord::Base, ActionController::Base, or
# MyBlacklistedClass, Outbacker will raise an exception.
#
# By default, ActiveRecord::Base and ActionController::Base
# are blacklisted. This is how Outbacker encourages skinny
# models, and discourages fat, obese models.
#
Outbacker.configure do |c|
  c.blacklist = [ActiveRecord::Base, ActionController::Base, MyBlacklistedClass]
end

#
# Specify where the Outbacker module can be included.
# If you try to include Outbacker within subclasses of any
# classes other than UseCase, ServiceObject, or DomainObject,
# Outbacker will raise an exception.
#
# The default is an empty whitelist, but specifying a whitelist
# is recommended way to configure this policy.
#
Outbacker.configure do |c|
  c.whitelist = [UseCase, ServiceObject, DomainObject]
end
