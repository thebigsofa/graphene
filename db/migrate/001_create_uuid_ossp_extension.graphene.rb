class CreateUuidOsspExtension < ActiveRecord::Migration[6.0]
  def change
    enable_extension "pgcrypto"
    enable_extension "uuid-ossp"
  end
end
