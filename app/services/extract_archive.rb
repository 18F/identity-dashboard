# Creates a tar.gz file of service provider logos and additional data
class ExtractArchive
  attr_reader :logo_attachments

  # @param destination In theory can be any IO object, though File objects are safest
  def initialize(destination)
    @destination = destination
    @logo_attachments = []
  end

  # @param models [Enumerable<ServiceProvider>]
  def add_logos_from_service_providers(models)
    models.each do |model|
      @logo_attachments.push({ filename: model.logo, attachment: model.logo_file })
    end
  end

  def add_json_file(data, filename)
    @json_data = data
    @json_filename = filename
  end

  def save
    return if logo_attachments.none?

    # Any output to `sgz` will be zipped first before going to `destination`
    sgz = Zlib::GzipWriter.new(destination)

    # Any output to `tar` will be an archive that goes to `sgz`
    # (And `sgz` will then zip it up first before sending to `destination`)
    tar = Minitar::Output.new(sgz)

    Minitar.pack_as_file(@json_filename, @json_data, tar) if @json_data && @json_filename

    logo_attachments.each do |data|
      logo_filename = data[:filename]
      logo_data = data[:attachment]
      logo_filename ||= attachment.blob.filename
      Minitar.pack_as_file(logo_filename.to_s, logo_data.download, tar)
    end
  ensure
    # According to Minitar docs:
    #
    # > `Minitar::Output#close` automatically closes both the Output object and the wrapped data
    # > stream object.
    tar.close
  end
end
