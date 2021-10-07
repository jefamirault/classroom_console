class GenerateSampleDataJob < ApplicationJob
  queue_as :default

  def perform(*args)

    # create a one-semester course and a year-long course
    # each course has 2 teachers, 5 sections
    # ~20 students per section, each student enrolled in one section from each course

    sample = {
        course: {
            sis_id: 1,
            name: 'Math',
        },
        sections: [
            {
                name: 'A Block',
                sis_id: 2,
                enrollments:
                    [
                        {
                          name: 'Alice',
                          role: 'student',
                          sis_id: 3
                        },
                        {
                            name: 'Bob',
                            role: 'student',
                            sis_id: 4
                        },
                        {
                            name: 'Charles',
                            role: 'teacher',
                            sis_id: 5
                        }
                    ]
            },
            {
                name: 'B Block',
                sis_id: 5,
                enrollments:
                    [
                        {
                            name: 'Don',
                            role: 'student',
                            sis_id: 6
                        },
                        {
                            name: 'Evelyn',
                            role: 'student',
                            sis_id: 7
                        },
                        {
                            name: 'Charles',
                            role: 'teacher',
                            sis_id: 5
                        }
                    ]

            }
        ]
    }
    puts "Success!"
  end
end