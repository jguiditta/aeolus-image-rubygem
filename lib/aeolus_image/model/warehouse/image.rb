#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

module Aeolus
  module Image
    module Warehouse
      class Image < WarehouseModel
        OS = Struct.new(:name, :version, :arch)

        @bucket_name = 'images'

        def initialize(obj)
          super
          @xml_body = Nokogiri::XML obj.body
        end

        def template_xml
          unless @template_xml
            begin
              # if an image is directly associated with template, use this
              if @template
                @template_xml = Template.find(@template).xml_body
              else
                @template_xml = Nokogiri::XML image_builds.first.target_images.first.target_template.body
              end
            rescue
              @template_xml = Nokogiri::XML "<template></template>"
            end
          end
          @template_xml
        end

        def latest_pushed_build
          ImageBuild.find(@latest_build) if @latest_build
        end

        def image_builds
          ImageBuild.where("($image == \"" + @uuid.to_s + "\")")
        end

        #TODO: We should get the image fields from the object body once we have it defined.
        def name
          unless @name
            @name = @xml_body.xpath("/image/name").text
            if @name.empty?
              @name = template_xml.xpath("/template/name").text
            end
          end
          @name
        end

        def os
          unless @os
            @os = OS.new(template_xml.xpath("/template/os/name").text, template_xml.xpath("/template/os/version").text, template_xml.xpath("/template/os/arch").text)
          end
          @os
        end

        def description
          unless @description
            @description = template_xml.xpath("/template/description").text
          end
          @description
        end

        # Delete this image and all child objects
        def delete!
          begin
            image_builds.each do |build|
              build.delete!
            end
          rescue NoMethodError
          end
          Image.delete(@uuid)
        end
      end
    end
  end
end
