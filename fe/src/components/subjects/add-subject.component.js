import React, { Component } from "react";
import SubjectDataService from "../../services/subject.service";

export default class AddSubject extends Component {
  constructor(props) {
    super(props);
    this.onChangeTitle = this.onChangeTitle.bind(this);
    this.onChangeDescription = this.onChangeDescription.bind(this);
    this.saveSubject = this.saveSubject.bind(this);
    this.newSubject = this.newSubject.bind(this);
    // this.retrieveGrades = this.retrieveGrades.bind(this);

    this.state = {
      grades: [],
      id: null,
      title: "",
      descr: "", 
      published: false
    };
  }

  // componentDidMount() {
  //   this.retrieveGrades();
  // }

  onChangeTitle(e) {
    this.setState({
      title: e.target.value
    });
  }

  onChangeDescription(e) {
    this.setState({
      descr: e.target.value
    });
  }

  onChangeGrade(e) {
    this.setState({
      grade_id: e.target.value
    });
  }
  
  // retrieveGrades() {
  //   GradeDataService.getAll()
  //     .then(response => {
  //       this.setState({
  //         grades: response.data
  //       });
  //       console.log(response.data);
  //     })
  //     .catch(e => {
  //       console.log(e);
  //     });
  // }

  saveSubject() {
    var data = {
      title: this.state.title,
      descr: this.state.descr
    };

    SubjectDataService.create(data)
      .then(response => {
        this.setState({
          id: response.data.id,
          title: response.data.title,
          descr: response.data.descr,
          published: response.data.published,

          submitted: true
        });
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  newSubject() {
    this.setState({
      id: null,
      title: "",
      descr: ""
    });
  }

  render() {
    return (
      <div className="submit-form">
        {this.state.submitted ? (
          <div>
            <h4>You submitted successfully!</h4>
            <button className="btn btn-success" onClick={this.newSubject}>
              Add
            </button>
          </div>
        ) : (
          <div>
            <div className="form-group">
              <label htmlFor="title">Title</label>
              <input
                type="text"
                className="form-control"
                id="title"
                required
                value={this.state.title}
                onChange={this.onChangeTitle}
                name="title"
              />
            </div>
            <div className="form-group">
              <label htmlFor="grade_id">Grade</label>
              <input
                type="text"
                className="form-control"
                id="grade_id"
                required
                value={this.state.grade_id}
                onChange={this.onChangeGrade}
                name="grade_id"
              />
            </div>
            <div className="form-group">
              <label htmlFor="descr">Description</label>
              <input
                type="text"
                className="form-control"
                id="descr"
                required
                value={this.state.descr}
                onChange={this.onChangeDescription}
                name="descr"
              />
            </div>

            <button onClick={this.saveSubject} className="btn btn-success">
              Submit
            </button>
          </div>
        )}
      </div>
    );
  }
}
