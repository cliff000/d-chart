class InquiryMailer < ApplicationMailer
    def send_mail(inquiry)
        @inquiry = inquiry
        mail(
            to:   'kkon1751@gmail.com',
            subject: 'お問い合わせ通知'
        )
    end
end
