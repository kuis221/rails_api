class PhotoInput < SimpleForm::Inputs::Base
  def input
    output_html = ''
    output_html << "<div class=\"uploading-panel\">
                    <p><a href=\"#\">Browse</a> for an image located on your computer</p>
                    <p class=\"divider\">OR</p>
                    <p>Drag and drop file here to upload</p>
                    <p class=\"small\">Maximun upload file size: 10MB</p>
                    </div>"
    output_html.html_safe
  end
end