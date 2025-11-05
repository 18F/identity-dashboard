# Creates a tar.gz file of service provider logos and additional data
class LogoArchive
  attr_reader :destination

  # @param destination In theory can be any IO object, though File objects are safest
  def initialize(destination)
    @destination = destination
    @attachments = []
  end

  def add_service_providers(models)
    models.each do |model|
      @attachments.push({ filename: model.logo, attachment: model.logo_file })
    end
  end

  def additional_data(data, filename)
    @additional_data = data
    @additional_data_filename = filename
  end

  def save
    return if @attachments.none?

    sgz = Zlib::GzipWriter.new(destination)
    tar = Minitar::Output.new(sgz)
    if @additional_data && @additional_data_filename
      Minitar.pack_as_file(@additional_data_filename, @additional_data, tar)
    end
    @attachments.each do |data|
      filename = data[:filename]
      attachment = data[:attachment]
      filename ||= attachment.blob.filename
      Minitar.pack_as_file(filename.to_s, attachment.download, tar)
    end
  ensure
    # According to Minitar docs:
    #
    # > `Minitar::Output#close` automatically closes both the Output object and the wrapped data
    # > stream object.
    tar.close
  end
end
