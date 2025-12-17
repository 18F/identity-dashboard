# Creates a tar.gz file of service provider logos and additional data
class ExtractArchive
  attr_reader :logo_attachments

  # @param destination In theory can be any IO object, though File objects are safest
  def initialize(destination)
    @destination = destination
    @logo_attachments = []
  end

  # @param logos [Array<Hash{Symbol=>String,ActiveStorage::Attached::One}>] an array of hashes where
  #   each hash is has a key `:filename`, a string <String>, and
  #   `:attachment` <ActiveStorage::Attached::One>}
  def add_logos(logos)
    @logo_attachments = @logo_attachments.union(logos)
  end

  def add_json_file(data, filename)
    @json_data = data
    @json_filename = filename
  end

  def save
    # Any output to `sgz` will be zipped first before going to `destination`
    sgz = Zlib::GzipWriter.new(@destination)

    # Any output to `tar` will be an archive that goes to `sgz`
    # (And `sgz` will then zip it up first before sending to `destination`)
    tar = Minitar::Output.new(sgz)
    if @json_data && @json_filename
      # Using `force_encoding('BINARY')` ensures non-ASCII-printable characters are preserved.
      # As nice as Minitar is, it doesn't leverage Ruby's string encoding tools well.
      # Because we're otherwise using Ruby's default string encodings everywhere, we don't have to
      # do anything when unpacking this data.
      Minitar.pack_as_file(@json_filename, @json_data.force_encoding('BINARY'), tar)
    end

    logo_attachments.each do |data|
      logo_data = data[:attachment]
      logo_filename = data[:filename] ||= logo_data.blob.filename
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
