class InquiryMailer < ApplicationMailer
    def send_mail(inquiry)
        @inquiry = inquiry
        mail(
            to:   'kcchart555@gmail.com',
            subject: 'KCChart お問い合わせ通知'
        )
    end
end
