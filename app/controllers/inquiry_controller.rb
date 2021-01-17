class InquiryController < ApplicationController
    layout 'inquiry'
    before_action :authenticate_account!

    def new
        @inquiry = Inquiry.new
    end

    def form
        @inquiry = Inquiry.new
    end

    def create
        @inquiry = Inquiry.new(inquiry_params)
        if @inquiry.save
            InquiryMailer.send_mail(@inquiry).deliver
            redirect_to "/mychart/"
        else
            redirect_to "/mychart/"
        end
    end
    
    private
    def inquiry_params
        params.require(:inquiry).permit(:name, :message)
    end
end
