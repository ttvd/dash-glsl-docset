require 'rubygems'
require 'mechanize'
require 'sqlite3'

EXTRACT_GLSL_PAGE   = "https://www.opengl.org/sdk/docs/man4/html"
EXTRACT_GLSL_DB     = "../docSet.dsidx"

a = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

# Remove any previous files.
if File.exists? EXTRACT_GLSL_DB
    File.unlink EXTRACT_GLSL_DB
end

# Create sqlite db.
db = SQLite3::Database.new(EXTRACT_GLSL_DB)
db.execute "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"
db.execute "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);"

a.get(EXTRACT_GLSL_PAGE + "/indexflat.php") do |page|

    # Grab all links on this page.
    page_links = page.links

    # Go through all links
    page_links.each do |link|

        # Skip non functional links.
        if link.attributes['target'].nil?
            next
        end

        # Skip introduction link.
        if link.to_s == "Introduction"
            next
        end
        
        # Skip all links which are gl functions ~ these have separate docset.
        if link.uri.to_s.match /^gl[^_]\w+/
            next
        end

        # At this point we should have only valid glsl entries.
        link_file = "#{link.to_s}.xhtml"

        # See if we need to remove previous file.
        if File.exist? link_file
            File.delete link_file
        end

        # Grab corresponding page.
        a.get(EXTRACT_GLSL_PAGE + "/#{link.uri.to_s}").save_as link_file

        # Insert into db.
        db.execute "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{link.to_s}', 'Function', '#{link_file}');"
    end
end

db.close
