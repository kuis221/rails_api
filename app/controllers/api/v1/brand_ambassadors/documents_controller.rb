module Api
  module V1
    module BrandAmbassadors
      class DocumentsController < Api::V1::FilteredController
        belongs_to :brand_ambassadors_visits, param: :visit_id, polymorphic: true, optional: true

        defaults resource_class: ::BrandAmbassadors::Document, collection_name: :brand_ambassadors_documents

        load_and_authorize_resource only: [:show, :edit, :update, :destroy],
                                    class: ::BrandAmbassadors::Visit

        authorize_resource only: [:create, :index],
                           class: ::BrandAmbassadors::Visit

        resource_description do
          name 'Brand Ambassadors Documents'
          short 'Documents'
          formats %w(json xml)
          error 400, 'Bad Request. he server cannot or will not process the request due to something that is perceived to be a client error.'
          error 401, 'Unauthorized access'
          error 404, 'The requested resource was not found'
          error 406, 'The server cannot return data in the requested format'
          error 422, 'Unprocessable Entity: The change could not be processed because of errors on the data'
          error 500, 'Server crashed for some reason. Possible because of missing required params or wrong parameters'
          description <<-EOS

          EOS
        end

        api :GET, '/api/v1/brand_ambassadors/documents', 'Obtain a list of documents and folders.'

        example <<-EOS
        GET /api/v1/brand_ambassadors/documents.json?visit_id=1&parent_id=12

        [
          {
            id: 10,
            name: "ACCOUNT LISTS",
            type: "folder",
            file_name: null,
            content_type: null,
            url: null,
            thumbnail: null
          },
          {
            id: 155,
            name: "BA BIOS",
            type: "folder",
            file_name: null,
            content_type: null,
            url: null,
            thumbnail: null
          },
          {
            id: 156,
            name: "BA EVENT PHOTOS",
            type: "folder",
            file_name: null,
            content_type: null,
            url: null,
            thumbnail: null
          },
          {
            id: 208341,
            name: "IMG_20140330_165611",
            type: "document",
            file_name: "IMG_20140330_165611.jpg",
            content_type: "image/jpeg",
            url: "https://s3.amazonaws.com/brandscopic-dev/brand_ambassadors/documents/files/000/208/341/original/IMG_20140330_165611.jpg?AWSAccessKeyId=AKIAIDG2GYLK4WMVHGPA&Expires=1414703372&Signature=wUdu6ssvH0mbW3Ws8JhH5YNc2mw%3D&response-content-disposition=attachment%3B%20filename%3DIMG_20140330_165611.jpg",
            thumbnail: "http://s3.amazonaws.com/brandscopic-dev/brand_ambassadors/documents/files/000/208/341/small/IMG_20140330_165611.jpg?1414459534"
          },
          {
            id: 8,
            name: "ORG CHART",
            type: "folder",
            file_name: null,
            content_type: null,
            url: null,
            thumbnail: null
          }
        ]
        EOS
        param :parent_id, :number, 'A valid folder id', required: false
        param :visit_id, :number, 'A valid visit id', required: false
        def index
          collection
        end

        protected

        def permitted_search_params
          params.permit(:page, :start_date, :end_date, { campaign: [] })
        end

        def skip_default_validation
          true
        end

        def collection
          @folder_children = (
            parent_document_folders.where(parent_id: params[:parent_id]) +
            folder.brand_ambassadors_documents.active.where(folder_id: params[:parent_id])
          ).sort_by { |a| a.name.downcase }
        end

        def folder
          @folder ||=
            if params[:parent_id]
              if params[:visit_id]
                current_company.brand_ambassadors_visits.find(params[:visit_id]).document_folders
              else
                current_company.document_folders
              end.find(params[:parent_id])
            elsif params[:visit_id]
              parent
            else
              current_company
            end
        end

        def parent_document_folders
          if params[:visit_id]
            folder.document_folders.active
          else
            folder.document_folders.active.where(folderable_id: current_company.id, folderable_type: 'Company')
          end
        end

        def begin_of_association_chain
          params[:visit_id].present? ? current_company : super
        end
      end
    end
  end
end