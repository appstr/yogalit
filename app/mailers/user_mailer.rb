class UserMailer < ApplicationMailer
  def teacher_verification_email(teacher_email)
    mail(to: teacher_email, subject: 'Account Verified', from:"Yogalit <no_reply@yogalit.com>")
  end

  def teacher_denial_email(teacher_email)
    mail(to: teacher_email, subject: 'Account Denied', from:"Yogalit <no_reply@yogalit.com>")
  end

  def student_blocked_email(student_email)
    mail(to: student_email, subject: 'Account Blocked', from:"Yogalit <no_reply@yogalit.com>")
  end

  def teacher_blocked_student_resolution_email(teacher_email)
    mail(to: teacher_email, subject: 'Student Blocked', from:"Yogalit <no_reply@yogalit.com>")
  end

  def teacher_blocked_email(teacher_email)
    mail(to: teacher_email, subject: 'Account Blocked', from:"Yogalit <no_reply@yogalit.com>")
  end

  def teacher_blacklisted_email(teacher_email)
    mail(to: teacher_email, subject: 'Account Blacklisted', from:"Yogalit <no_reply@yogalit.com>")
  end

  def teacher_emergency_cancel_email(teacher_email)
    mail(to: teacher_email, subject: 'Emergency Cancellation', from:"Yogalit <no_reply@yogalit.com>")
  end

  def new_yoga_session_booked_email(student_email, teacher_email)
    mail(to: [student_email, teacher_email], subject: 'New Yoga Session!', from:"Yogalit <no_reply@yogalit.com>")
  end

  def student_refund_email(student_email)
    mail(to: student_email, subject: 'Yogalit Refund', from:"Yogalit <no_reply@yogalit.com>")
  end

  def general_refund_denial(student_email)
    mail(to: student_email, subject: 'Refund Denial', from:"Yogalit <no_reply@yogalit.com>")
  end

  def custom_refund_denial(student_email, message)
    mail(to: student_email, subject: 'Refund Denial', from:"Yogalit <no_reply@yogalit.com>")
  end

  def message_to_yogalit(new_message)
    @new_message = new_message
    mail(to: "yogalityoga@gmail.com", subject: 'New Yogalit Message', from:"Yogalit <no_reply@yogalit.com>")
  end
end
