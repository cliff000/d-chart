class AdminController < ApplicationController
    layout 'admin'
    before_action :authenticate_account!

    def inquiry_list
        permitOnlyAdmin()
        @inquiryList = Inquiry.all
    end

    def export
        permitOnlyAdmin()
    end

    def export_accounts
        @allAccounts = Account.all
    end
    def export_matches
        @allMatches = Match.all
    end

    def user_list
        permitOnlyAdmin()
        @data = Account.all
    end

    def inquiry_delete
        obj = Inquiry.find(params[:id])
        obj.destroy
        redirect_to '/admin/inquiry_list/'
    end

    private

    def permitOnlyAdmin
        if current_account.id != 1
            redirect_to "/mychart/"
        end
    end
end
