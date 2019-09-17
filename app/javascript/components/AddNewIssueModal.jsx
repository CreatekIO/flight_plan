import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button, Header, Image, Modal, Select, Form } from 'semantic-ui-react';
import { ticketCreated } from '../action_creators';

const formFields = ['repo_id', 'description', 'title'];

class AddNewIssueModal extends Component {
    state = {
        title: '',
        description: '',
        repo_id: '',
        repo_id_error: '',
        description_error: '',
        title_error: ''
    };

    handleChange = (e, { name, value }) => {
        this.setState({ [name]: value });
    };

    handleClose = () => {
        this.setState({
            showModal: false,
            repo_id_error: '',
            description_error: '',
            title_error: ''
        });
    };

    handleOpen = () => {
        this.setState({ showModal: true });
    };

    handleSubmit = () => {
        this.handleErrors();

        var fieldsPopulated = formFields.every(this.fieldBlank);
        if (fieldsPopulated) {
            this.setState({ showModal: false });
            this.props.ticketCreated({
                title: this.state.title,
                description: this.state.description,
                repo_id: this.state.repo_id
            });
        }
    };

    fieldBlank = field => {
        return (
            this.state[field]
                .toString()
                .split(' ')
                .join('').length > 0
        );
    };

    handleErrors = () => {
        formFields.forEach(
            function(field) {
                if (
                    this.state[field]
                        .toString()
                        .split(' ')
                        .join('').length === 0
                ) {
                    this.setState({
                        [field + '_error']: "can't be blank"
                    });
                } else {
                    this.setState({ [field + '_error']: '' });
                }
            }.bind(this)
        );
    };

    boardRepos = () => {
        return flightPlanConfig.currentBoardRepos.map((repo, index, array) => ({
            key: index,
            text: repo.name,
            value: repo.id
        }));
    };

    render() {
        return (
            <Modal
                onClose={this.handleClose}
                onOpen={this.handleOpen}
                open={this.state.showModal}
                id={'add-new-issue-modal'}
                trigger={<a className="item">Add an issue</a>}>
                <Modal.Header>Add a new issue</Modal.Header>
                <Modal.Content>
                    <Form onSubmit={this.handleSubmit}>
                        <div className="field">
                            <label>Repository</label>
                            <div className="issue-error">
                                {this.state.repo_id_error}
                            </div>
                            <Select
                                placeholder={this.boardRepos()[0].text}
                                name="repo_id"
                                options={this.boardRepos()}
                                onChange={this.handleChange}
                            />
                        </div>
                        <label>Title</label>
                        <div className="issue-error">
                            {this.state.title_error}
                        </div>
                        <Form.Input
                            placeholder={'Issue title'}
                            name="title"
                            onChange={this.handleChange}
                        />
                        <label>Description</label>
                        <div className="issue-error">
                            {this.state.description_error}
                        </div>
                        <Form.TextArea
                            placeholder={'Issue description'}
                            name="description"
                            onChange={this.handleChange}
                        />
                        <Form.Button>Submit</Form.Button>
                    </Form>
                </Modal.Content>
            </Modal>
        );
    }
}

export default connect(null, { ticketCreated })(AddNewIssueModal);
