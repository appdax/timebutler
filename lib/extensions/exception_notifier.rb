
# Wrapps the display_error_message method from Rake to send an email when an
# expection has been occured.
module ExceptionNotifier
  # Add alias method chain around the display_error_message method
  # when the module got included into Rake.
  def self.included(klass)
    klass.class_eval do
      alias_method :orig_display_error_message, :display_error_message
      alias_method :display_error_message, :overriden_display_error_message
    end
  end

  # Call overriden method and send notification.
  #
  # @param [ Exception ] e The thrown exception.
  #
  # @return [ Void ]
  def overriden_display_error_message(e)
    orig_display_error_message(e)
    send_expection(e)
  end

  private

  # Reconstruct the invoked command line.
  #
  # @return [ String ]
  def command_line
    "rake #{ARGV.join(' ')}"
  end

  # Send email notification about the thrown exception.
  #
  # @param [ Exception ] e The thrown exception.
  #
  # @return [ Void ]
  def send_expection(e)
    require 'net/http'

    uri = URI(ENV['MAILGUN_URL'])

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req.basic_auth 'api', ENV['MAILGUN_KEY']
      req.set_form_data email_payload(e)

      http.request(req)
    end
  end

  # Form data with all information about the expection.
  #
  # @param [ Exception ] e The thrown exception.
  #
  # @return [ Hash ]
  def email_payload(e)
    { from: ENV['MAILGUN_FROM'],
      to: ENV['MAILGUN_TO'],
      subject: ENV['DOCKERCLOUD_SERVICE_HOSTNAME'],
      text: [command_line, e.inspect].concat(e.backtrace.take(10)).join("\n") }
  end
end

if defined?(Rake) && ENV['MAILGUN_KEY']
  Rake.application.instance_eval do
    class << self
      include ExceptionNotifier
    end
  end
end
